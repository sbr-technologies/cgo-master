require 'rexml/document'
require 'ftools'

class JobImportWorker 

  SFTP_DIRECTORY = "/mnt/ftp"
  ERRORS_DIRECTORY = "/mnt/ftp_errors"
  ARCHIVE_DIRECTORY = "/mnt/ftp_archive"

  def perform

    begin

      logger.debug("Starting Job Upload: #{SFTP_DIRECTORY}")
      logger.info("Upload Jobs Started with SFTP Directory: #{SFTP_DIRECTORY}")

      now = Time.now.to_date

      # Read SFTP Dir and deterimine wich files to load.
      Dir.chdir(SFTP_DIRECTORY)
      @files = Dir.glob("*.xml").sort {|a,b| File.new(a).mtime <=> File.new(b).mtime}

      if @files.any? {|file| file.match(/jobcentral/i) }
        jobcentral_recruiter = Recruiter.find :first, :conditions => "username = 'jobcentral'"
        jobcentral_recruiter.jobs.clear
      end

      @files.each do |filename|

        logger.info("Processing file: #{filename}")

        # filename is expected to be formated as: <usename>_<optional_yyymmdd>.xml
        username  = filename[/^(.*?)(?:_(\d{8,8}).*)?(\.xml)$/, 1]
        logger.info("Recruiter (admin) is: #{username}")
        recruiter = Recruiter.find :first, :conditions => ["username = ?", username  ]

        # Skip to next file if we can't find the recruiter.
        if recruiter.nil?
          File.move(filename, ERRORS_DIRECTORY)
          logger.error("Can't find recruiter for file #{filename}")
          Administrator.root_admin.messages << Message.new(:body => "Invalid file #{filename} found in FTP Directory. Can't find matching recruiter account")
          UserMailer.deliver_invalid_filename_in_ftp_folder(filename)
          next
        end

        # Check that employer has job posting privileges
        if recruiter.employer.job_post_allowed? == false
          File.move(filename, ERRORS_DIRECTORY)
          logger.error("Employer does not have Job Import Privileges: #{recruiter.employer.name} in file #{filename}")
          Administrator.root_admin.messages << Message.new(:body => "Employer does not have Job Import Privileges: #{recruiter.employer.name} in file #{filename}")
          UserMailer.deliver_employer_does_not_have_job_posting_privileges_notification(filename, recruiter.employer.name)
          next
        end

        # Check that jobs are uploaded on the "EMPLOYER ADMIN" account.
        if recruiter.has_role?(:employer_admin) == false
          File.move(filename, ERRORS_DIRECTORY)
          logger.error("Recruiter must have role 'employer_admin': Processing jobs for #{recruiter.name} in file #{filename}")
          Administrator.root_admin.messages << Message.new(:body => "Recruiter must have role 'employer_admin': Processing jobs for #{recruiter.name} in file #{filename}")
          UserMailer.deliver_employer_is_not_an_admin_notification(filename, recruiter)
          next
        end

        logger.info("Recruiter is: #{recruiter.name}")

        # Delete all recruiter's jobs if the employer's profile indicates "Erase all jobs before upload"
        recruiter.jobs.clear if recruiter.employer.is_replace_all_on_import? && !filename.match(/jobcentral/i)

        begin
          doc = REXML::Document.new(File.open(filename, "r"))
          count = success = 0
          errors = Array.new

          doc.elements.each("jobs/job") do |job_data|
            job	     = filename.match(/jobcentral/i) ? new_job_from_jobcentral(job_data) : new_job_from_xml(job_data)
            location = filename.match(/jobcentral/i) ? new_location_from_jobcentral(job_data) : new_location_from_xml(job_data)
            count+=1

            logger.debug("Processing Job #{job.code}/#{job.title}");
            begin
              Job.transaction do
                errors.push("row #{count}: [#{location.errors.collect {|k,v| "#{k}=>'#{v}'"}.join(' ')}]") if !location.valid?
                job.location = location
                job.expires_at = now + Constants::DEFAULT_PUBLISH_PERIOD
                recruiter.jobs << job # Job is saved
                errors.push("[#{job.code}] #{job.title} (row:#{count}): #{job.errors.collect {|k,v| "#{k}=>'#{v}'"}.join(' ')}") if !job.valid?
                success+=1 if location.valid? && job.valid?
              end
            rescue => e
              logger.error(e.message + "####" + e.backtrace.join('####'))
            end
          end

        rescue => e
          File.move(filename, ERRORS_DIRECTORY)
          has_fatal_errors = true
          logger.error("Unable to parse file #{filename}, error: #{e}")
          logger.error(e.backtrace.join('\r'))
          recruiter.messages << Message.new( :body => "Your file: '#{filename}' seems to be malformed and it could not be processed.")
          Administrator.root_admin.messages << Message.new(:body => "Job Upload Failed: Incorrect format for #{filename}; unable to parse XML")
        end

        unless has_fatal_errors

          recruiter.messages << Message.new( :body => "Your file: '#{filename}' was processed. Uploaded #{success} jobs out of a total of #{count}.")
          Administrator.root_admin.messages << Message.new(:body => "Job Upload Completed for file #{filename}. Uploaded #{success} jobs out of a total of #{count}.")

          logger.info("Imported #{success} jobs from #{filename}, Errors: #{count-success}")

          if count-success != 0
            # move to ftp_errors
            File.move(filename, ERRORS_DIRECTORY)
            logger.error("Filename #{filename} had errors during import:")
            errors.each {|e| logger.error "\t#{e}" }
            logger.error("---------------------- END OF: #{filename} ------")
            UserMailer.deliver_job_upload_with_errors_notification(recruiter.email, filename, errors)
          else
            # move to ftp_archive
            File.move(filename, ARCHIVE_DIRECTORY)
          end
        end

      end # files.each do ...

      logger.info("End of jobs_upload")

    rescue => err
      # Top level error reporting
      logger.error("TOP LEVEL ERROR HANDLER: #{err.inspect}")
      logger.error("#{err.backtrace.join('\n')}")
    end

  end



private

  def new_job_from_xml(job_data)

    logger.debug("New Job from XML")
    
    Job.new(
      :code						=> (job_data.elements["pub_code"].text rescue nil),
      :title					=> (job_data.elements["job_title"].text rescue nil),
      :description				=> sanitize_html(job_data.elements["job_description"].text, 'br'),
      :requirements				=> job_data.elements["job_requirements"].text.to_s.blank? ? nil : sanitize_html(job_data.elements["job_requirements"].text, 'br'),
      :expires_at				=> (job_data.elements["job_expires_at"].text rescue nil),
      :education_level			=> (job_data.elements["job_education_level"].text || 0 rescue 0),
      :experience_required		=> (job_data.elements["job_experience_required"].text rescue nil),
      :payrate					=> (job_data.elements["job_payrate"].text rescue nil),
      :hr_website_url			=> (job_data.elements["job_hr_website_url"].text rescue nil),
      :online_application_url	=> (job_data.elements["job_online_application_url"].text rescue nil),
      :security_clearance		=> (job_data.elements["job_security_clearance"].text || 0 rescue 0),
      :travel_requirements		=> (job_data.elements["job_travel_requirements"].text || 0 rescue 0),
      :relocation_cost_paid		=> (job_data.elements["job_relocation_cost_paid"].text rescue nil) || "not_paid",
      :show_company_profile		=> (job_data.elements["job_show_company_profile"].text rescue nil) || true
    )
  end

  def new_job_from_jobcentral(job_data)

    logger.debug("New Job from Jobcentral")

    Job.new(
      :code						=> (job_data.elements["guid"].text rescue nil),
      :company_name				=> (job_data.elements["employer"].text rescue nil),
      :title					=> (job_data.elements["title"].text rescue nil),
      :description				=> (job_data.elements["description"].text rescue nil),
      :requirements				=> nil,
      :expires_at				=> (job_data.elements["expiration_date"].text rescue nil),
      :education_level			=> 0,
      :experience_required		=> true,
      :payrate					=> nil,
      :hr_website_url			=> nil,
      :online_application_url	=> (job_data.elements["link"].text rescue nil),
      :security_clearance		=> 0,
      :travel_requirements		=> 0,
      :relocation_cost_paid		=> "not_paid",
      :show_company_profile		=> true
    )
  end


  def new_location(job_data, from_jobcentral = false)
    (from_jobcentral && new_location_from_jobcentral(job_data)) || new_location_from_xml(job_data)
  end


  def new_location_from_xml(job_data)
    Address.new(
      :label			=> "location",
      :street_address1	=> (job_data.elements["job_location_address1"].text rescue nil),
      :street_address2	=> (job_data.elements["job_location_address2"].text rescue nil),
      :city				=> (job_data.elements["job_location_city"].text rescue nil),
      :state			=> (job_data.elements["job_location_state"].text rescue "0"),
      :zip				=> (job_data.elements["job_location_zip"].text rescue "00000"),
      :country			=> (job_data.elements["job_location_country"].text rescue nil),
      :email			=> (job_data.elements["job_location_email"].text rescue nil),
      :phone			=> (job_data.elements["job_location_phone"].text rescue nil),
      :mobile			=> (job_data.elements["job_location_mobile_phone"].text rescue nil),
      :fax				=> (job_data.elements["job_location_fax"].text rescue nil),
      :website			=> (job_data.elements["job_location_website"].text rescue nil)
    )
  end

  def new_location_from_jobcentral(job_data)

    addr = (job_data.elements["location"].text.split(",") || [] rescue [])
    country = (Constants::COUNTRIES.select {|entry| entry[:label].upcase == job_data.elements["country"].text.upcase}[0][:id] if job_data.elements["country"]) || 214

    Address.new(
      :label			=> "location",
      :street_address1	=> nil,
      :street_address2	=> nil,
      :city				=> addr[0],
      :state			=> addr[1],
      :zip				=> addr[2],
      :country			=> country,
      :email			=> nil,
      :phone			=> nil,
      :mobile			=> nil,
      :fax				=> nil,
      :website			=> nil
    )
  end


  #
  # $Id: sanitize.rb 3 2005-04-05 12:51:14Z dwight $
  #
  # Copyright (c) 2005 Dwight Shih
  # A derived work of the Perl version:
  # Copyright (c) 2002 Brad Choate, bradchoate.com
  #
  # Permission is hereby granted, free of charge, to
  # any person obtaining a copy of this software and
  # associated documentation files (the "Software"), to
  # deal in the Software without restriction, including
  # without limitation the rights to use, copy, modify,
  # merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to
  # whom the Software is furnished to do so, subject to
  # the following conditions:
  #
  # The above copyright notice and this permission
  # notice shall be included in all copies or
  # substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
  # OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  # LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND
  # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
  # COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
  # OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  # CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
  # OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  # OTHER DEALINGS IN THE SOFTWARE.
  #

  def sanitize_html( html, okTags='' )
    # no closing tag necessary for these
    soloTags = ["br","hr"]

    # Build hash of allowed tags with allowed attributes
    tags = okTags.downcase().split(',').collect!{ |s| s.split(' ') }
    allowed = Hash.new
    tags.each do |s|
      key = s.shift
      allowed[key] = s
    end

    # Analyze all <> elements
    stack = Array.new
    result = html.gsub( /(<.*?>)/m ) do | element |
    if element =~ /\A<\/(\w+)/ then
      # </tag>
      tag = $1.downcase
      if allowed.include?(tag) && stack.include?(tag) then
        # If allowed and on the stack
        # Then pop down the stack
        top = stack.pop
        out = "</#{top}>"
        until top == tag do
                        top = stack.pop
                        out << "</#{top}>"
        end
        out
      end

    elsif element =~ /\A<(\w+)\s*\/>/
      # <tag />
      tag = $1.downcase
      if allowed.include?(tag) then
        "<#{tag} />"
      end

    elsif element =~ /\A<(\w+)/ then
      # <tag ...>
      tag = $1.downcase
      if allowed.include?(tag) then
        if ! soloTags.include?(tag) then
          stack.push(tag)
        end
        if allowed[tag].length == 0 then
          # no allowed attributes
          "<#{tag}>"
        else
          # allowed attributes?
          out = "<#{tag}"
          while ( $' =~ /(\w+)=("[^"]+")/ )
            attr = $1.downcase
            valu = $2
            if allowed[tag].include?(attr) then
              out << " #{attr}=#{valu}"
            end
          end
          out << ">"
        end
      end
    end
    end

    # eat up unmatched leading >
    while result.sub!(/\A([^<]*)>/m) { $1 } do end

    # eat up unmatched trailing <
    while result.sub!(/<([^>]*)\Z/m) { $1 } do end

    # clean up the stack
    if stack.length > 0 then
      result << "</#{stack.reverse.join('></')}>"
    end

    result
  end


end


