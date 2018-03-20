class RegistrationsController < ApplicationController
  
  before_filter :login_required, :except => ["new_from_affiliate", "post_from_affiliate"]
  
  # require_role  :recruiter, :only => ["new", "create"]
  require_role	:admin,			:only => ["edit", "update", "enable_search", "destroy"]

  def show
    @registration = current_user.registrations.find(params[:id]) 

  rescue 
    redirect_to welcome_path 
  end


  def new
    jobfair = Jobfair.find params[:jobfair_id]


    if current_user.is_a?(Applicant)
      if !current_user.registered?(jobfair)
        
        # Applicants can register to security clearance jobfair only if their security clearance status is NOT 3:"none". 
        if current_user.security_clearance == '3' && (jobfair.security_clearance_required || jobfair.category == 'security_clearance')
          flash[:notice] = "You must have a security clearance to register to this jobfair"
          redirect_to jobfairs_path
          return
        end

        if !jobfair.applicant_can_register?(current_user)
            flash[:notice] = "This Job Fair is for Officers and NCOs Only"
            redirect_to jobfairs_path
        end

        # Process Applicant registration, no need to present a form.
	    if current_user.register_for(jobfair)
		  flash[:notice] = "Thank you for registering to #{jobfair.name}"
		else
		  flash[:error] = "We encountered a problem processing your registration for #{jobfair.name}, contact support"
		end
	  else
	    flash[:notice] = "You are already register for #{jobfair.name}"
	  end

	  redirect_to jobfairs_path
	  return
    end

	# if current_user is a recruiter present registration form. (new.html.erb)
   
	@registration = Registration.new(:jobfair => jobfair)
	@registration.banner_company_name = current_user.employer.name
	@registration.fax = current_user.addresses[:primary].fax
	@registration.url = current_user.employer.website
	@registration.lunches_required = 2;
	@registration.available_positions = current_user.employer.profile unless current_user.employer.profile == Employer::DEFAULT_PROFILE_TEXT

  end

  
  def create
    @jobfair = Jobfair.find(params[:jobfair_id])

    # Only Officers O-*, W-*, E-7, E-8, E-9 can register to Military Officer Jobfair.
    if current_user.type == "Applicant"
      if !@jobfair.applicant_can_register?(current_user)
          flash[:notice] = "This Job Fair is for officers and NCOs Only"
          redirect_to jobfairs_path
      end
    end

    if(current_user.register_for(@jobfair, params[:registration]))
      flash[:notice] = "Thank you for registering for #{@jobfair.name}"
    else
      flash[:notice] = "You were already registered for #{@jobfair.name}"
    end
	  redirect_to jobfairs_path
  end

  def edit
	@registration = Registration.find params[:id]
  end

  def update
	@registration = Registration.find params[:id]
	@registration.update_attributes(params[:registration])

	flash[:notice] = "Your changes have been saved"
	redirect_to admin_employer_path(@registration.attendant.employer)
  end

  # if called with method GET; present an extended registration form. If called with POST, validate 
  # info and send emails about this new registration. 
  # DO NOT Save in the DB. 
  # DO NOT Require a logged in user. 
  # If a valid jobfair_id param is supplied, fix the jobfair registration to the specified jobfair; 
  # otherwise present a drop down box with upcoming jobfairs. 
  def new_from_affiliate

    @external_registration = ExternalJobfairRegistration.new()
    @jobfair = Jobfair.find params[:jobfair_id] if params[:jobfair_id]
    @jobfair = Jobfair.all_upcoming if @jobfair.nil? 

    render :layout => false 

  end


  def post_from_affiliate
    @registration = ExternalJobfairRegistration.new(params[:external_registration])
    logger.debug(@registration.inspect)
    logger.debug("Is this valid? #{@registration.valid?}")

    @jobfair = Jobfair.find params[:jobfair_id]
    if !@registration.valid?
      render :layout => false, :action => "new_from_affiliate"
    else


      UserMailer.deliver_new_jobfair_registration_from_affiliate(@registration, @jobfair)


      render :layout => false
    end

  end


  # Service AJAX request from admin/employer view page.
  # to allow / disallow search resumes by jobfair.
  def enable_search
	@registration = Registration.find params[:id]
	@registration.enable_search = params[:enable] == "yes" ? true : false;
	@registration.save

	render :nothing => true
  end
  
end
