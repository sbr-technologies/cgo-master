require "constants"

class ApplicantController < ApplicationController

  before_filter :login_required, :except => ["new", "create", "deactivate", "process_deactivation"]
  require_role  :applicant,      :except => ["new", "create", "show", "deactivate", "process_deactivation"]
  require_role  [:applicant, :recruiter, :employer_admin] , :only => ["show"]
 
  def index
    @applicant = Applicant.find current_user.id

    @messages_inbox = @applicant.messages(:order => "created_at", :limit => 25)
    @inbox = @applicant.inbox_entries.paginate(:page => params[:page] || 1)
    @registrations = @applicant.registrations.select { |registration| registration.jobfair.date > Date.yesterday }
    @registrations.sort! {|a,b| a.jobfair.date <=> b.jobfair.date}
    @applications = @applicant.job_applications
    @show_new_authentication_modal = @applicant.authentications.empty? && @applicant.social_login_enabled
  end

  def show
    @applicant = Applicant.find params[:id]
    @resume = @applicant.resume

    unless current_user.blank? || !current_user.is_a?(Recruiter)
      recruiter = Recruiter.find current_user.id
      recruiter.increment_resume_views_stat
      #recruiter.count_resume_views = (recruiter.count_resume_views + 1 rescue 0)
      #recruiter.save!
    end

    render :layout => "application_full"
  end

  def photo
    send_data File.new(current_user.photo.path, "r").read, :content_type => current_user.photo.content_type, :disposition => "inline"
  end


  def search
    respond_to do |format|
      format.html {}
      format.js { raise "Not Implemented" }
    end
  end

 
  def new
    @applicant = Applicant.new()
    @address = Address.new(:label => 'primary')
    #@applicant.resume = Resume.new(:visibility => 'public')

    if session[:omniauth] && session[:omniauth]["provider"] == "linked_in"
      linkedin_profile = @applicant.fetch_linkedin_profile(
        ["first-name", "last-name", "headline", "summary", "positions", "educations",  "picture-url"], 
        session[:omniauth]["credentials"]["token"], 
        session[:omniauth]["credentials"]["secret"]
      )

      unless linkedin_profile.nil? || linkedin_profile.empty?
        @social_media_account = true
        populate_from_linkedin(@applicant)
      end

      render :layout => "application_full"

    end

    # Set Default Values
    @applicant.us_citizen = true
    @applicant.willing_to_relocate = true

    render :layout => "application_full"

  end

  def create
    @applicant = Applicant.new(params[:applicant]) 
    @address = Address.new(params[:address])

    if session[:omniauth] && session[:omniauth]["provider"] == "linked_in"
      authentication = Authentication.new_from_linked_in session[:omniauth] 
      @applicant.authentications << authentication
      @applicant.username = @applicant.email || authentication.generate_username 
    end

    # Set the correct source website (REA, ROA, etc)
    @applicant.source = source_website

    # Disable email verification per Carl's request 8/31/09
    # Re-enabled due to bogus applicant accounts Apr 7, 2012
    @applicant.make_activation_code
    @applicant.status = "inactive"

    # @applicant.activation_code = nil
    # @applicant.activated_at = Time.now
    # @applicant.status = "active"

    # Set correct role.
    @applicant.add_role("applicant")
    
    Applicant.transaction do
      @applicant.addresses << @address
      @applicant.save!
    end

    @applicant.delay.fetch_linkedin_connections unless @applicant.authentications.empty?
    session[:omniauth] = nil

    # Create a session for the new applicant. 
    # self.current_user = User.authenticate @applicant.username, @applicant.password
    
    flash[:notice] = "Your account has been created and an email has been sent to your email address on file.  Please click the activation link in the email’s body."

    redirect_to welcome_path
    
  rescue ActiveRecord::ActiveRecordError 
    @address.valid?
    #@resume.valid?
    render :action => "new", :layout => "application_full"
  end
  

  def edit
    @applicant = Applicant.find(params[:id])
    @address = @applicant.addresses[:primary] || Address.new(:label => "primary")  

    Rails.logger.debug("params['linkedin']=#{params['linkedin']}")
    if @applicant && !params["linkedin"].nil?
      Rails.logger.debug("Fetching LinkedIn Information")
      profile = @applicant.fetch_linkedin_profile(
        ["first-name", "last-name", "headline", "summary", "positions", "educations",  "picture-url"]
      )
      unless profile.nil?
        flash[:notice] = "We succesfuly imported LinkedIn information, please verify in MyAccount"
        populate_from_linkedin(@applicant, profile) 
      else
        flash[:notice] = "We encountered a problem fetching your information, please try later"
        # TODO: Delete LinkedIn Authorization if this error is returned. 
      end
    end

  end

  def update

    @applicant = Applicant.find(params[:id])
    @address = Address.new(params[:address].merge({:label => "primary"}))
    Applicant.transaction do
      @applicant.update_attributes!(params[:applicant]) 

      if numeric?(params[:applicant][:"availability_date(1i)"])
          @applicant.availability_date = Date.civil(
              params[:applicant][:"availability_date(1i)"].to_i,
              params[:applicant][:"availability_date(2i)"].to_i,
              1
          )
      else
          @applicant.availability_date = nil
      end

	  @applicant.update_or_create_address(params[:address].merge({:label => "primary"}))
      @applicant.save!
    end

    flash[:notice] = "Your changes have been saved"
    redirect_to edit_applicant_path(@applicant.id)
    
  rescue ActiveRecord::ActiveRecordError 
    @address.valid?
    render :action => "edit"
  end

  def enable_social_login
    user = User.find current_user.id
    user.social_login_enabled = !params[:applicant][:social_login_enabled]
    user.save!

    render :nothing => true 
  end


  def apply
    job = Job.find(params[:application][:job_id])
    unless current_user.applied?(job)
      Applicant.transaction do
        application = JobApplication.new(:job => job)
        current_user.job_applications << application
	    current_user.save!

        job.employer.increment_job_applicants_stat
      end
    end

    render :text => "<div class='flash notice'>Your application was succesfuly processed</div>"

  rescue ActiveRecord::ActiveRecordError => err
    logger.debug err
    render :text => "<div class='flash error'>Your application could not be processed. Please contact administrator</div>"
  end

  def deactivate
    @applicant = Applicant.new
    render :layout => "login"
  end

  def process_deactivation
    @message = ""
    @applicant = Applicant.find_by_username_and_password(params[:username], params[:password]); 
    if not @applicant.nil?
      @applicant.status = "inactive"
      @applicant.save!
    else
      @message = "Invalid Username or Password; please try again"
    end

    render :layout => "login"
  end

  protected

  def numeric?(object) 
    true if Float(object) rescue false
  end

  def populate_from_linkedin(applicant, linkedin_profile)
    Rails.logger.debug("LinkedIn Profile: " + linkedin_profile.inspect);
    applicant.first_name = linkedin_profile["firstName"]
    applicant.last_name  = linkedin_profile["lastName"]
    applicant.title      = linkedin_profile["headline"]
    applicant.summary    = linkedin_profile["summary"]

    applicant.positions << Position.build_from_linkedin(linkedin_profile["positions"])
    applicant.educations << Education.build_from_linkedin(linkedin_profile["educations"])
  end

end
