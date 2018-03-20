require "constants" 

class ResumesController < ApplicationController

  layout "application"

  before_filter :login_required, :except => ["guest_search", "guest_index"]

  require_role :applicant, :except => ["guest_index", "show", "search", "add_to_inbox", "remove_from_inbox", "guest_search", "print", "forward", "download", "attachment"]
  require_role [:recruiter, :employer_admin], :except => ["guest_index", "search", "show", "index", "preview", "new", "create", "edit", "update", "download","guest_search", "print", "attachment"]


  MAX_SEARCH_RATE = 0.5 # fraction of a second

  VALID_UPLOAD_FORMATS = [".docx", ".doc", ".html", ".txt"]
  
  def index
    current_user.resume ||= Resume.new(:visibility => :public) 
    @resume = current_user.resume
  end

  def guest_index
  end

  def guest_search

    # Do not process empty queries
    unless params[:q].to_s.blank?
    
      # Fix unclosed quotes, and uppercase logical opperands.
      unless(params[:q][:keyword].to_s.blank?)
        query = params[:q][:keyword]
        query = query.delete('"') if query.count('"') % 2 > 0
        query = query.delete("'") if query.count("'") % 2 > 0
        query = query.gsub(/\s+or\s+/, ' OR ').gsub(/\s+and\s+/, ' AND ')
      end

      @applicants = Applicant.search do
        paginate(:page => params[:page] || 1, :per_page => Constants::PAGE_SIZE )
        order_by(:posted_date, :desc)

        if(query)
          keywords(query) {minimum_match 1}
        else
          keywords(params[:q][:applicant_last_name].downcase, :fields =>[:last_name])
        end

        with(:state).any_of(([] << params[:q][:state]).flatten) unless params[:q][:state].to_s.blank?

        with(:type_of_applicant).any_of(([] << params[:q][:type_of_applicant]).flatten) unless params[:q][:type_of_applicant].to_s.blank?
        with(:branch_of_service).any_of(([] << params[:q][:branch_of_service]).flatten) unless params[:q][:branch_of_service].to_s.blank?
        with(:security_clearance).any_of(([] << params[:q][:security_clearance]).flatten) unless params[:q][:security_clearance].to_s.blank?
        with(:education_level).any_of(([] << params[:q][:education_level]).flatten) unless params[:q][:education_level].to_s.blank?

        unless params[:q][:posted_date].to_s.empty?
          how_many = (params[:q][:posted_date] == "one-month" and 1) || (params[:q][:posted_date] == "three-months" and 3) || 6
          with :posted_date, how_many.months.ago.to_date.to_s(:yyyymmdd) .. Date.today.to_s(:yyyymmdd)
        end

        with(:willing_to_relocate).equal_to(params[:q][:willing_to_relocate]) unless params[:q][:willing_to_relocate].to_s.blank?

      end
    end
  end

  def search

    # Skip processing of empty queries
    return if params[:q].to_s.blank?
    
    # Check privileges
    (render(:template => 'resumes/not_enough_privileges') and return false) if !current_user.employer.resume_search_allowed?
    (flash.now[:error]="You need to provide a job code for this search") and return if(current_user.employer.is_federal_employer? && params[:job_code].to_s.blank?)
    (flash.now[:error]="You need to provide at least one keyword for this search") and return if(params[:q].to_s.blank? || (params[:q][:keyword].to_s.blank? && params[:q][:applicant_last_name].to_s.blank?))
    
    # clear session highlights if new search
    session[:highlights] = nil if params[:page].nil? || params[:page] == 1

    @job_code = params[:job_code]
    session[:previous_search_tstamp] = Time.now.to_f

    # Update date of last resume search. 
    unless current_user.blank? || !current_user.is_a?(Recruiter)
      recruiter = Recruiter.find current_user.id
      recruiter.last_resume_search_date = Time.now
      recruiter.increment_resume_searches_stat
      #recruiter.count_resume_searches = (recruiter.count_resume_searches + 1 rescue 0)
      #recruiter.save!
    end

    # Fix unclosed quotes, and uppercase logical opperands.
    unless(params[:q][:keyword].to_s.blank?)
      query = params[:q][:keyword]
      query = query.delete('"') if query.count('"') % 2 > 0
      query = query.delete("'") if query.count("'") % 2 > 0
    end

    @applicants = Applicant.search do
      paginate(:page => params[:page] || 1, :per_page => Constants::PAGE_SIZE )
      order_by(:posted_date, :desc)

      if(query)
        keywords(query) {minimum_match 1}
      else
        keywords(params[:q][:applicant_last_name].downcase, :fields =>[:last_name])
      end

      # Only Active Applicants !!
      with(:status).equal_to(:active)

      with(:state).any_of(([] << params[:q][:state]).flatten) unless params[:q][:state].to_s.blank?

      with(:type_of_applicant).any_of(([] << params[:q][:type_of_applicant]).flatten) unless params[:q][:type_of_applicant].to_s.blank?
      with(:branch_of_service).any_of(([] << params[:q][:branch_of_service]).flatten) unless params[:q][:branch_of_service].to_s.blank?
      with(:security_clearance).any_of(([] << params[:q][:security_clearance]).flatten) unless params[:q][:security_clearance].to_s.blank?
      with(:education_level).any_of(([] << params[:q][:education_level]).flatten) unless params[:q][:education_level].to_s.blank?

      unless params[:q][:posted_date].to_s.empty?
        how_many = (params[:q][:posted_date] == "one-month" and 1) || (params[:q][:posted_date] == "three-months" and 3) || 6
        with :posted_date, how_many.months.ago.to_date.to_s(:yyyymmdd) .. Date.today.to_s(:yyyymmdd)

      end

      with(:willing_to_relocate).equal_to(params[:q][:willing_to_relocate]) unless params[:q][:willing_to_relocate].to_s.blank?

      job_fair_registrations = [params[:q][:job_fair_registrations]].flatten.compact
      job_fair_registrations = job_fair_registrations.select { |jfr| !jfr.to_s.blank? } 

      if !current_user.nil? && !current_user.employer.resume_search_privileges? && current_user.employer.jobfair_search_allowed?
          job_fair_registrations += current_user.employer.recruiters.collect { |recruiter|
              recruiter.registrations
          }.flatten.uniq.collect {|r| r.jobfair.id if r.enable_search == true}.compact
      end
      
      with(:job_fair_registrations).any_of(job_fair_registrations) unless job_fair_registrations.empty?

    end

    if(@applicants.hits.length > 0) 
      # Store highlights in session, so we can highlight text in 'show'
      session[:keyword] = params[:q][:keyword]

      # Store job code and query for OFCCP Reporting.
      if params[:job_code]
        session[:ofccp_job_code] = params[:job_code] 
        session[:ofccp_search_q] = params[:q].collect {|k,v| "#{k}:#{v.to_a.join(',')}" unless v.to_s.blank?}.compact.join(' AND ')
      else
        session[:ofccp_job_code] = nil
        session[:ofccp_search_q] = nil
      end
    end

  end


  def show
    @resume = Resume.find(params[:id]) # if current_user.resume.id == params[:id] || current_user.is_a(Recruiter)

    if params[:job_code]
        # Log OFFCP if we are viewing this resume from Search Results.
        Ofccp.log(current_user.employer.id, params[:job_code], params[:query], @resume.applicant, current_user) if params[:query]
    end

  end
    
  def new
    @resume = Resume.new
  end

  def create
    @resume = Resume.new

    # I must check that file format is valid BEFORE assigning to @resume.attached_resume
    # otherwise I get a parsing exception. Bug on paperclip?
    return render(:action => "new") unless valid_attachment_extension? 

    @resume.attributes = params[:resume]
    # @resume.attached_resume = get_html_text_as_stream if @resume.input_method == "manual"
    
    current_user.resume = @resume
    @resume.save!
    
    flash[:notice] = "You have posted your resume. We will process it shortly."

    redirect_to applicants_path

  rescue ActiveRecord::ActiveRecordError
    render :action => "new"
  end
  
  def edit
    @resume = current_user.resume
    respond_to do |format|
      format.html
      format.js {render :template => 'resumes/edit_modal.html.erb'}
    end
  end

  def update
    @resume = current_user.resume

    unless params[:resume][:attached_resume].to_s.blank?
      
      # I must check that file format is valid BEFORE assigning to @resume.attached_resume
      # otherwise I get a parsing exception. Bug on paperclip?
      unless valid_attachment_extension? 
        flash[:error] = "Your resume is not saved; valid document formats are [#{VALID_UPLOAD_FORMATS.join(', ')}]"
        return render(:action => "index")  
      end

      @resume.attributes = params[:resume]
    else
      @resume.visibility = params[:resume][:visibility]
    end

    raise ActiveRecord::ActiveRecordError unless @resume.valid?
    @resume.save! 

    flash[:notice] = "Your document has been uploaded."
    redirect_to resumes_path

  rescue ActiveRecord::ActiveRecordError 
    Rails.logger.error @resume.errors
    flash[:error] = "We encountered a problem saving your resume; Please try again later"
    redirect_to resumes_path
  end


  def print
    @resume = Resume.find(params[:id])
    # text = @resume.formatted_text(:web) 
    # render :text => text
    render :layout=> false
  end

  def add_to_inbox
    @resume = Resume.find params[:id]
    unless current_user.inbox_entries.contains?(@resume)
      current_user.inbox_entries << InboxEntry.new(:resource => @resume, :added_by => "user")
    end

  rescue ActiveRecord::ActiveRecordError => e
    logger.error "Unable to insert inbox entry for user [#{current_user.username}:#{current_user.id}]: Error: #{e}"
  end

  def remove_from_inbox
    @entry = current_user.inbox_entries.find :first, :conditions => ["resource_id = ? AND resource_type = 'Resume'", params[:id] ]
    unless @entry.nil? 
      @entry.destroy 
    else
      render :nothing => true 
    end


  rescue ActiveRecord::ActiveRecordError => e
    logger.error "Unable to remove inbox entry for user [#{current_user.username}:#{current_user.id}]: Error: #{e}"
  end


  def forward
    unless params[:forward][:recipients].to_s.blank?
      @resume = Resume.find params[:id]
      unless @resume.nil?
        # Log OFFCP 
        Ofccp.log(current_user.employer.id, session[:ofccp_job_code], session[:ofccp_search_q], @resume.applicant, current_user) if session[:ofccp_job_code] 

        @recipients = params[:forward][:recipients].split(/,|\s/)
        UserMailer.forward_resume(current_user, @resume, @recipients).deliver
      end
    end
    
    render :nothing => true 
  end

  def attachment
    @resume = Resume.find params[:id]
    @keyword = session[:keyword] || ""

    if @resume && @resume.attached_resume

      # Log OFFCP 
      if session[:ofccp_job_code] 
        Ofccp.log(current_user.employer.id, session[:ofccp_job_code], session[:ofccp_search_q], @resume.applicant, current_user) 
      end

      text = @resume.formatted_text(:web).html_safe

      logger.debug("Is HTML Safe? #{text.html_safe?}")

      # I'm trying to highlight keyword matches. But, the problem is that
      # the HTML version of .docx documents keeps the paragraphs within <span>
      # tags, hence any highlighting tag (i.e. <em>keyword</em>) is not interpreted
      # as HTML but literaly as text. This is a problem.
      #
          
      # These GSUBs are intended to clean the Keywords before processing, for example:  
      # (Ruby OR "Ruby On Rails") AND Programmer)
      # should be break up into individual words, discarding all boolean opperators;
      # this is: [Ruby, Ruby, On, Rails, Programmer]
      #
     #.gsub!(/[()";.\/]/, "").gsub!(/OR|AND|NOT/i, "")

      @keyword.gsub(/['",.;:]/, "").split(/\s+/).each do |kword|
        logger.debug("Highlighting KEYWORD: #{kword}")
        text.gsub!(/(\s+|[(>])(#{kword.gsub(/[().*;:?!+]/,'')})([.;,:]?\s*)/i, "\\1<b style='background-color:yellow'>\\2</b>\\3") unless kword == "AND" || kword == "OR"
      end

      # END OF HIGHLIGHTING EXPERIMENTAL CODE

      render :text => text, :content_type => "text/html"
    end
  end


  # Download a resume, if a docx version is available provide that one, otherwise
  # provide an HTML/text version of the document. 
  def download
     @resume = Resume.find params[:id]

     # Log OFFCP 
     if session[:ofccp_job_code] 
        Ofccp.log(current_user.employer.id, session[:ofccp_job_code], session[:ofccp_search_q], @resume.applicant, current_user) 
     end

     if File.exist?(@resume.attached_resume.path(:doc))
        send_file @resume.attached_resume.path(:doc),
                  :filename => "#{@resume.applicant.first_name}_#{@resume.applicant.last_name}_resume.doc", :type => Mime::Type.lookup_by_extension("doc").to_s
     elsif File.exist?(@resume.attached_resume.path(:docx))
        send_file @resume.attached_resume.path(:docx), 
                  :filename => "#{@resume.applicant.first_name}_#{@resume.applicant.last_name}_resume.docx", :type => Mime::Type.lookup_by_extension("docx").to_s
     elsif File.exist?(@resume.attached_resume.path(:pdf))
        send_file @resume.attached_resume.path(:pdf), 
                  :filename => "#{@resume.applicant.first_name}_#{@resume.applicant.last_name}_resume.pdf", :type => Mime::Type.lookup_by_extension("pdf").to_s
     elsif File.exist?(@resume.attached_resume.path(:txt))
        send_file @resume.attached_resume.path(:txt), 
                  :filename => "#{@resume.applicant.first_name}_#{@resume.applicant.last_name}_resume.txt", :type => Mime::Type.lookup_by_extension("txt").to_s
     else
        send_data @resume.formatted_text(:web), :filename => "#{basename}.html", :type => "text/html", :disposition => "attachment"
     end
  end


private

  def get_html_text_as_stream
    ios = StringIO.new(params[:html_text])
    ios.content_type = "text/html"
    ios.original_filename = "resume_#{@resume.id}.html"

    return ios
  end

  def valid_attachment_extension?
    if(!params[:resume][:attached_resume].to_s.blank? &&
       !VALID_UPLOAD_FORMATS.include?(File.extname(params[:resume][:attached_resume].original_filename)) )

       @resume.errors.add(:attached_resume, "is not valid. Please check it is saved in an accepted format (#{VALID_UPLOAD_FORMATS.join(', ')})")
       return false
    else
      return true
     end
  end


end
