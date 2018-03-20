require "csv"
require "zip/zip"
require "zip/zipfilesystem"

require "custom_tempfile"

class ResumesUploadJob

  def initialize(jobfair_id, headersFilename, resumesFilename)
    @jobfair_id = jobfair_id
    @headersFilename = headersFilename
    @resumesFilename = resumesFilename
  end


  def perform

    @warnings = []
    @total_records = 0
    @total_rejected = 0
    @total_resumes = 0
    @total_headers = 0
    @total_updated = 0
    @total_created = 0
    now = Time.new

    @jobfair = Jobfair.find @jobfair_id
    passw_filename = "/mnt/outgoing/applicant_passw_#{@jobfair.date.to_s(:human_short).tr(' ', '_')}_#{@jobfair.location.gsub(/[\s,-]/,'_').gsub(/_+/, "_").gsub(/['\?\":!\/]/, "")}.csv"
    File.delete(passw_filename) rescue nil; # Delete if it exists
    passw_writer = CSV.open(passw_filename,	"wb")

    Zip::ZipFile.open(@headersFilename)  { |hzip|

      # ... And read Resume Files
      Zip::ZipFile.open(@resumesFilename) { |rzip|

        # Process each header / resume file.
        hzip.dir.entries('.').sort.each do |hfilename|
            @total_records += 1
            @total_headers += 1
            
            Delayed::Worker.logger.info("Processing: #{hfilename}")

            begin

              rfilename = "r#{hfilename.from(1).chomp('.txt')}"
              line = CSV.parse(hzip.file.read(hfilename)).flatten

              # Get a Hash of Applicant properties (delete unused fields, then extract address fields).
              header = Hash[*HEADER_FORMAT.zip(line).flatten]

              header[:branch_of_service] = get_lookup_by_label(
                  Constants::BRANCH_OF_SERVICE, 
                  "UNSPESIFIED"
              ) if header[:branch_of_service].nil? || !valid_lookup?(Constants::BRANCH_OF_SERVICE, header[:branch_of_service])

              header[:education_level] = get_lookup_by_label(
                  Constants::EDUCATION_LEVEL, 
                  "UNSPESIFIED"
              ) if header[:education_level].nil? || !valid_lookup?(Constants::EDUCATION_LEVEL, header[:education_level])

              header[:occupational_preference] = get_lookup_by_label(Constants::OCCUPATIONAL_PREFERENCE, "UNSPESIFIED")

              header[:security_clearance] = get_lookup_by_label(
                  Constants::SECURITY_CLEARANCE, 
                  "UNSPESIFIED"
              ) if header[:security_clearance].nil? || !valid_lookup?(Constants::SECURITY_CLEARANCE, header[:security_clearance])

              header[:type_of_applicant] = get_lookup_by_label(
                  Constants::TYPE_OF_APPLICANT, 
                  "UNSPESIFIED"
              ) if(header[:type_of_applicant].nil? || !valid_lookup?(Constants::TYPE_OF_APPLICANT, header[:type_of_applicant]))

              header[:willing_to_relocate] == "no" ? header[:willing_to_relocate] = false : header[:willing_to_relocate] = true

              header[:availability_date] = (header[:availability_date] =~ /NOW/i ? nil : (Date.strptime(header[:availability_date], "%m-%d-%Y") rescue ( Date.strptime(header[:availability_date], "%m/%d/%Y") rescue nil)))

              header[:roles] = "applicant"

              UNUSED_FIELDS.each {|field| header.delete(field)}
              address_data = Hash[*ADDRESS_FIELDS.collect {|field| [field, header.delete(field)]}.flatten]
              address_data[:email] = header[:email]

            rescue ArgumentError => e
              Delayed::Worker.logger.error("Argument Error")
              Delayed::Worker.logger.error(e)
            end

            # Locate Applicant. Found? do update, otherwise create
            applicant = Applicant.where("email = :email OR username = :email", {:email => header[:email]}).first()

            begin
              # new applicant?
              if applicant.nil?

                  @total_created += 1

                  header.merge!({
                    :username => header[:email],
                    :password => Applicant.get_random_password,
                    :imported_at => now,
                    :source => @jobfair.sponsor
                  })

                  address = Address.new({:label => "primary", :skip_validation => true}.merge(address_data))
                  applicant = Applicant.new(header)
                  #applicant.make_activation_code
                  applicant.activation_code = nil
                  applicant.activated_at = Time.now
                  applicant.status = "active"
                  applicant.add_role("applicant")

                  Applicant.transaction do
                    applicant.save!
                    applicant.addresses << address

                    resume = Resume.new({ :visibility => "public"})
                    tmpf = generate_resume_file(rzip, rfilename, applicant)

                    if(tmpf)
                      resume.attached_resume = tmpf
                      applicant.resume = resume 
                      @total_resumes += 1
                    end

                    # Write to Passwords File, so Carl can do mailing of welcome letters with username and passwords
                    passw_writer << [applicant.email, applicant.first_name, applicant.last_name, applicant.username, applicant.password]
                  end

              # applicant exists. Update !!
              else

                  @total_updated += 1

                  Delayed::Worker.logger.info("Applicant Exists. Updating !!")

                  Applicant.transaction do

                    if applicant.resume && (!File.exist?(applicant.resume.attached_resume.path) rescue false)
                      applicant.resume.destroy
                      applicant.resume = Resume.new(:visibility => "public")
                      applicant.resume.save!
                    end

                    applicant.status = "active" # Reactivate if inactive. 
                    #applicant.resume = Resume.new({:visibility => "public"}) if applicant.resume.nil?

                    tmpf = generate_resume_file(rzip, rfilename, applicant)
                    
                    if(tmpf) 
                      unless applicant.resume.nil?
                        applicant.resume.destroy
                        Delayed::Worker.logger.info("Destroying old Resume")
                      end

                      applicant.resume = Resume.new(:visibility => 'public')
                      applicant.resume.attached_resume = tmpf
                      applicant.resume.save!
                      @total_resumes += 1
                    else
                      Delayed::Worker.logger.error("Can't find Resume File for #{rfilename}");
                    end

                    applicant.update_attributes(header)
                    applicant.addresses[:primary].update_attributes(address_data) if !applicant.addresses[:primary].nil?

                    #applicant.resume.update_attribute(:updated_at, Time.now) 
                    #applicant.save!
                  end
              end
              
              # Applicant is now either new or updated, register to the jobfair.
              applicant.save!
              applicant.register_for(@jobfair)

            rescue ActiveRecord::ActiveRecordError
              unless applicant.nil? || address.nil?
                applicant.valid? 
                address.valid? 
                @warnings.push({:filename => hfilename, :errors => [applicant.errors, address.errors]})
                Rails.logger.info("Warning: Applicant or Address not valid: #{hfilename} #{applicant.errors.inspect} #{address.errors.inspect}")
              else
                @warnings.push({:filename => hfilename, :errors => ["Unknown Error trying to create account"]})
                Rails.logger.info("Warning: error trying to create or update header: #{hfilename}")
              end

              @total_rejected += 1

            rescue RSolr::RequestError => e
              @warnings.push({:filename => hfilename, :errors => ["Error Saving To Solr"]})
              Delayed::Worker.logger.error("Error Saving to Solr #{hfilename}")
              Delayed::Worker.logger.error(e);

            rescue ArgumentError => e
              Delayed::Worker.logger.error("Exception: #{e}");
            end
        end
      }
    }

    # Close Passwords File
    passw_writer.close

    # Notify job upload results to Administrator
    Rails.logger.info("Uploaded resumes for Job Fair: #{@jobfair.name} on #{Date.today}, stats: Total Headers:[#{@total_headers}] Total Resumes: #{@total_resumes} Total Created: #{@total_created} Total Updated: #{@total_updated} Rejected:[#{@total_rejected}]")
    Administrator.root_admin.messages << Message.new(:body => "Uploaded resumes for Job Fair: #{@jobfair.name} on #{Date.today}, stats: Total Headers:[#{@total_headers}] Total Resumes: #{@total_resumes} Total Created: #{@total_created} Total Updated: #{@total_updated} Rejected:[#{@total_rejected}]")
    UserMailer.deliver_resumes_upload_complete_notification(@jobfair, @total_headers, @total_resumes, @total_created, @total_updated, @total_rejected, @warnings, passw_filename)
  end


  def generate_resume_file(rzip, rfilename, applicant)

      tmpf = nil
      extension = ""

      ["doc", "docx", "txt"].each { |ext| 
        extension =  ext if rzip.find_entry("#{rfilename}.#{ext}")
      }

      unless extension.blank? 
        Delayed::Worker.logger.info("Loading Resume Text, extension: " + extension)
        begin
          tmpf = CustomTempfile.new("resume_for_#{applicant.id}.#{extension}")
          tmpf.write(rzip.file.open("#{rfilename}.#{extension}") {|io| io.read})
        rescue Exception => e
          Delayed::Worker.logger.error(e)
          tmpf = nil 
        end
      else
        Delayed::Worker.logger.error("Can't find Resume File for #{rfilename}");
      end

      return tmpf
  end



  def valid_lookup?(lookup, id)
    lookup.any? {|item| item[:id] == id}
  end

  def get_lookup_by_label(lookup, label)
    return (lookup.first { |item| item[:label] == label }[:id]  rescue nil)
  end




  UNUSED_FIELDS = [
    :objective,
    :company,
    :first_year,
    :misc,
    :unknown
  ]

  HEADER_FORMAT = [
    :first_name, 
    :last_name, 
    :street_address1, 
    :city, 
    :state, 
    :country, 
    :zip, 
    :phone, 
    :email, 
    :objective, 
    :company, 
    :first_year, 
    :misc, 
    :unknown, 
    :type_of_applicant, 
    :branch_of_service, 
    :security_clearance , 
    :education_level, 
    :willing_to_relocate, 
    :availability_date
  ]

  ADDRESS_FIELDS = [ 
    :street_address1, 
    :city, 
    :state, 
    :country, 
    :zip, 
    :phone
  ]

		
end
