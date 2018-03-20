class AuthenticationController < ApplicationController

  before_filter :login_required, :except => [:create, :link]

  def index
    @authentications = current_user.authentications
  end

  def new
    @authentications = current_user.authentications

    respond_to do |format|
      format.html
      format.js { render :template => '/authentication/new.html.erb' }
    end
  end

  def create
    omniauth = request.env['omniauth.auth'] 
    authentication = Authentication.find_by_provider_and_uid(params[:provider], omniauth['uid'])

    # login with authentication
    if authentication
      # Not doing login by LinkedIn anymore 
      #self.current_user = authentication.user
      flash[:notice] = "Success! You have authorized CGO to access your LinkedIn Account."
      redirect_back_or_default(request.env['omniauth.origin'] || (current_user.has_role?('applicant') ? welcome_path : employers_path) )

    # existing user: create new authentication and login
    elsif current_user
      current_user.authentications.create!(
        :provider => params[:provider], 
        :uid => omniauth['uid'], 
        :access_token => omniauth["credentials"]["token"],
        :token_secret => omniauth["credentials"]["secret"]
      )
      current_user.fetch_linkedin_connections

      flash[:notice] = "Your '#{params[:provider].titleize}' account has been added to CGO."

    # new user, new authentication: Prompt to link or create
    else
      session[:omniauth] = omniauth
      render "user/new_or_link", :layout => "login"
    end

  end

  def failure
    flash[:notice] = params[:message]
    redirect_to welcome_url
  end

  def link
    self.current_user = User.authenticate(params[:username], params[:password])

    if logged_in?

      if session[:omniauth]["provider"] == "linked_in"
        current_user.authentications.create!(
          :provider => session[:omniauth]["provider"] ,
          :uid => session[:omniauth]["uid"],
          :access_token => session[:omniauth]["credentials"]["token"],
          :token_secret => session[:omniauth]["credentials"]["secret"]
        )
      end

      session[:omniauth] = nil

      flash[:notice] = "Your Corporate Gray profile is now connected to your LinkedIn account"
      if(current_user.has_role?("applicant"))
        redirect_to applicants_path
      else
        redirect_to employer_path(current_user.id)
      end
    else
      flash[:error] = "Invalid username or password; please try again"
      render "applicant/new_or_link", :layout => "login"
    end
    
  end

end
