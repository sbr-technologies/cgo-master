class SessionController < ApplicationController
  
  before_filter :login_required, :except => ["new", "create", "activate", "password_reminder"]
  skip_before_filter :block_inactive_account, :only => ["index", "destroy"]

  def new
    render :layout => "login"
  end

  def create

    default_path = "/"

    self.current_user = User.authenticate(params[:username], params[:password])
    
    if logged_in?
      
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:cgo_auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end

      if current_user.has_role?(:applicant)
        if current_user.social_login_enabled && current_user.authentications.empty?
          @show_new_authentication_modal = true
        end

        if current_user.has_role?(:applicant) && !current_user.authentications.find_by_provider(:linked_in).blank?
          current_user.fetch_linkedin_connections if !current_user.connections.blank? && current_user.connections.maximum(:created_at) < 1.month.ago
        end

        default_path = applicants_path

      elsif current_user.has_role?(:recruiter) || current_user.has_role?(:employer_admin)
        default_path = dashboard_employer_recruiter_path(:employer_id => current_user.employer.id, :id => current_user.id)
        current_user.increment_login_count_stat
      end

      flash[:notice] = "Welcome back #{current_user.name}"
      redirect_back_or_default(default_path)

    else # NOT LOGGED IN !
      flash.now[:error] = "Invalid Login".html_safe
      render :action => 'new', :layout => "login"
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end
  
  def activate
    user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if user && !user.active?
      user.activate
      flash[:notice] = "Your account is now active. You can login to use member-only services" if user.has_role?(:applicant) || user.has_role?(:employer_admin)
      flash[:notice] = "Your account is now verifyied. Contact #{user.employer.administrator.name} to activate your account" if user.has_role?(:recruiter)
    else
      flash[:notice] = "Invalid activation code"
    end
    redirect_to('/')
  end

  
  def password_reminder
    if params[:username]
      user = User.find_by_username params[:username]
      user = User.find_by_email params[:username] if(user.nil?)

      if not user.nil?
        UserMailer.deliver_password_reminder(user)
        flash[:notice] = "Your Username and Password have been mailed"
      else
        flash[:notice] = 
          "We could not find an account with the username supplied; \
           Please <a style='color:#E6901A' href='/sessions/password_reminder'>try again</a> \
           or contact <a style='color:#E6901A' href='mailto:#{UserMailer::admin_email}?subject=Password%20Reminder'>\
           CGO Customer Service</a>"
      end
      redirect_to welcome_path
      return
    end

    render :layout => 'login'
  end
  
end
