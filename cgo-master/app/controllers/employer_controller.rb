class EmployerController < ApplicationController

  before_filter :login_required, :except => ["new", "create", "index", "job_fairs", "public_profile", "services"]
  require_role  [:employer_admin, :recruiter], :except => ["edit", "update", "new", "create", "index", "job_fairs", "public_profile", "services"]
  require_role  :employer_admin, :only   => ["edit", "update"]

  before_filter :find_model, :except => ["index", "show", "new", "create","job_fairs", "services"]
  
  def index
    if params[:query] && !params[:query].blank?
      @query = params[:query] #.split(" ")[0] 
      @employers = Employer.joins(:recruiters).where(["name like ? AND users.roles like '%employer_admin%'" , "#{@query}%"]).order(:name).limit(5).all
      # @employers = Employer.find :all, :conditions => ["name like ?" , "#{@query}%"], :order => "name", :limit => 5
    end

    respond_to do |format|
      format.html { render :layout => "application_full" }
      format.js
    end
  end

  def services
    if params[:query] && !params[:query].blank?
      @query = params[:query].split(" ")[0] 
      @employers = Employer.find :all, :conditions => ["name like ?" , "#{@query}%"], :order => "name", :limit => 5
    end

    respond_to do |format|
      format.html

      # Responds to AJAX calls made on new employer form
      format.js

      # Dec 28th, 2011: Commented by Federico. I don't know if this is still in use. I believe that it's not.
      # format.xls {
      #   logger.debug("Rendering to XLS")
      #     headers['Content-Type'] = "application/vnd.ms-excel"
      #     headers['Content-disposition'] = 'attachment;filename=employers.csv'   
      #     render :layout=>false
      # 
      # } if params[:format]=='xls' #Hack for IE

    end

  end



  # Employer.Show: this shows the employer's info, which is mainly the employer's users. 
  def show
    @users = current_user.employer.recruiters.sort! {|a,b| a.first_name + a.last_name <=> b.first_name + b.last_name} # if current_user.has_role?("account_owner")
  end

  # Create new employer: Create new Employer along with its "notification" Address and the first employer's Recruiter (default admin).
  def new
    @employer = Employer.new
    @employer.is_replace_all_on_import = true

    @recruiter = Recruiter.new
    @address = Address.new(:label => "primary")
  end


  def create

    @recruiter = Recruiter.new(params[:recruiter])
    @employer = (Employer.find(params[:recruiter][:employer_id]) if !params[:recruiter][:employer_id].blank?) || Employer.new(params[:employer])
    @address = Address.new(params[:address])

    new_employer_account = false
  
    Employer.transaction do
   
      if @employer.new_record?
        @recruiter.add_role("employer_admin")
        new_employer_account = true
        @employer.save!
      else
        @recruiter.add_role("recruiter")
        new_employer_account = false
      end

      # Disabled per Carl's request; Always active  and send message to employer admin
      # @recruiter.status = new_employer_account ? "active" : "inactive"
      @recruiter.status =  "active" 

      if session[:omniauth] && session[:omniauth]["provider"] == "linked_in"
        authentication = Authentication.new_from_linked_in session[:omniauth] 
        @recruiter.authentications << authentication
        @recruiter.username = @recruiter.email || authentication.generate_username 
      end

      # Disable email verification per Carl's request 08/31/09
      #@recruiter.make_activation_code
      @recruiter.activation_code = nil
      @recruiter.activated_at = Time.now
      @recruiter.addresses << @address

      @employer.recruiters << @recruiter
      unless @recruiter.valid? && @address.valid?

        logger.debug(@recruiter.errors.inspect)
        logger.debug(@address.errors.inspect)

        render :action => "new"
        return
      end

    end

    UserMailer.deliver_new_employer_account_notification(@recruiter) if new_employer_account

    flash[:notice] = "Account Created; login to begin."
    redirect_to new_session_path

  rescue ActiveRecord::ActiveRecordError
    @recruiter.valid?
    @address.valid? 
    render :action => "new"
  end
  
  def edit
  end

  def update
    @employer.update_attributes(params[:employer])
    flash[:notice] = "Your changes have been saved"
    redirect_to employer_recruiters_path(:employer_id => current_user.employer.id)
  end



  def job_fairs
    @display_fees = true
    render :template => "jobfair/index.html.erb"
  end


  def public_profile
    @employer = Employer.find params[:id]
    @jobs = @employer.jobs.find :all, :limit => 25, :order => "created_at DESC"
    @jobs = @jobs.select {|j| j.active? && !j.expired?}

    @employer.increment_profile_view_stat
  end

private 

  def find_model
    @employer = Employer.find(params[:id]) 
  end

 
end
