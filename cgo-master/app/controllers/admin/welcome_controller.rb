require "constants" 

class Admin::WelcomeController < ApplicationController

  layout "admin/layouts/application"

  before_filter :login_required
  require_role(:admin)


  def index
    @messages_inbox = WillPaginate::Collection.create(params[:page] || 1, Constants::PAGE_SIZE) do |pager|
      results = current_user.messages.find(:all, :offset => pager.offset, :limit => pager.per_page)
      pager.replace(results)
      pager.total_entries = current_user.messages.count unless pager.total_entries
    end

    @total_applicants = Applicant.count :conditions => ["status = 'active'"]
    @total_resumes = Resume.count
    @total_employers = Employer.count
  end


  def request_authsub_authorization

    client = GData::Client::DocList.new

    next_url = url_for(:controller => controller_name, :action => :authsub_response)
    secure = false  # set secure = true for signed AuthSub requests
    sess = true
    # domain = 'example.com'  # force users to login to a Google Apps hosted domain
    authsub_link = client.authsub_url(next_url, secure, sess, nil, "https://docs.google.com/feeds/ http://spreadsheets.google.com/feeds/ https://docs.googleusercontent.com")

    redirect_to authsub_link
  end


  def authsub_response

    client = GData::Client::DocList.new

    client.authsub_token = params[:token] # extract the single-use token from the URL query params
    session_token = client.auth_handler.upgrade()

    token = AuthsubToken.new(:token => session_token)
    token.save!
    
  end

end
