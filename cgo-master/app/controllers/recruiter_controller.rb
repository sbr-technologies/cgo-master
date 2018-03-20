require "constants.rb"

class RecruiterController < ApplicationController
  
  before_filter :login_required
  require_role	:employer_admin, :only => ["new", "create", "destroy"]
  
  def index
    @recruiters = current_employer.recruiters.find(:all, :conditions => ["id != ?", current_user.id], :order => "first_name, last_name DESC")
  end

  def dashboard
    @messages_inbox = current_user.messages.find(:all, :limit => 25)
    @resumes_inbox = current_user.inbox_entries(:limit => Constants::MAX_INBOX_SIZE).sort_by { |entry| entry.created_at.to_date }
    inbox_applicants = current_user.inbox_entries.collect {|entry| entry.resource ? entry.resource.applicant : nil}.compact
    @applicants = WillPaginate::Collection.create(1, 25, inbox_applicants.size) do |pager|
       pager.replace(inbox_applicants)
    end
    
    @registrations = current_user.registrations.select {|registration| registration.jobfair.date > Time.now.to_date}
  end

  def show
    @recruiter = current_employer.recruiters.find(params[:id])
  end

  def new
    
    if current_employer.recruiters.size >= current_employer.max_recruiters
      logger.info("#{current_employer.name} has reached the maximum number of recruiters allowed ")
      flash[:notice]="You have reached the maximum number of recruiters allowed for your organization"
      redirect_to employer_recruiters_path(current_employer.id) 
    end
    
    @recruiter = Recruiter.new
    @address =  Address.new(:label => 'primary')
  end

  
  def create
    @recruiter = Recruiter.new(params[:recruiter])

    # Disable email verification per Carl's request.
    #@recruiter.make_activation_code
    @recruiter.activation_code = nil
    @recruiter.activated_at = Time.now
    @recruiter.status = "active"

    @recruiter.add_role("recruiter")
    @address = Address.new(params[:address])
    current_employer.recruiters << @recruiter

    Recruiter.transaction do
      @recruiter.save!
      @recruiter.addresses << @address
    end
    
    flash[:notice] = "Your changes have been saved"
    redirect_to employer_recruiters_path(current_employer.id)
    
  rescue ActiveRecord::ActiveRecordError
    @address.valid?
    render :action => "new"
  end
  
  def edit
    @recruiter = current_employer.recruiters.find(params[:id])
    @address = @recruiter.addresses[:primary] || Address.new(:label => "primary")
  end
  
  def update
    @recruiter = current_employer.recruiters.find(params[:id])
    
    Recruiter.transaction do
      @recruiter.update_or_create_address(params[:address])
      @recruiter.update_attributes!(params[:recruiter])
    end
    
    flash[:notice] = "Your changes to #{@recruiter.name}\' profile have been saved"
    redirect_to(employer_recruiter_path(:employer_id => current_employer.id, :id => current_user.id))  and return
    
  rescue ActiveRecord::ActiveRecordError => e
    @recruiter.valid?
    @address = params[:address]

    flash[:error] = e.to_s
    render :action => "edit"
  end
  
  def destroy
    current_user.employer.recruiters.find(params[:id]).destroy
    redirect_to employer_recruiters_path(:id => current_user.employer.id)
  end
  
  # AJAX update of recruiter's status
  def current_status
    @recruiter = current_employer.recruiters.find(params[:id])
    @recruiter.update_attribute(:status, params[:s])
    render :nothing => true
  end


  
end
