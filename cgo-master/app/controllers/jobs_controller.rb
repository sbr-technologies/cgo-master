require "constants"

class JobsController < ApplicationController

    layout "application"

    before_filter :login_required, :except => ["search", "public_profile", "auto_complete_for_employer_name"]
    require_role [:employer_admin, :recruiter], :except => ["search", "public_profile", "search", "show", "add_to_inbox", "apply_notify", "remove_from_inbox", "auto_complete_for_employer_name"]
    require_role [:applicant, :recruiter, :employer_admin], :only => ["show"]

    def auto_complete_for_employer_name
      respond_to do |format|
        format.xhr {
          results = Employer.find :all, :include => ["recruiters"], :conditions => ["name like ?", params[:employer][:name]+'%' ]
          @employers = results.select {|e| e.recruiters.any? {|r| r.has_role?("employer_admin")} }
          render :layout => false
        }
      end
    end


    def index
      @jobs = current_user.jobs.paginate :page => params[:page] || 1, :order => "created_at DESC"
    end


    def search

      require_applicant_menu

      # Return if no query parameter
      return unless params[:q].present? 

      @keywords = params[:q][:keyword]
      @states = params[:q][:state]

      employer_name = @employer_name = (params[:employer][:name] rescue nil)
      recruiters = []
      unless employer_name.blank? 
        recruiters = Employer.where("name like '%#{employer_name}%'").collect { |e| e.recruiters.collect {|r| r.id} }.flatten
      end

      # Display a message and return if there is no keyword
      ((flash.now[:error] = "You must provide at least one keyword or an existing company name for your search" ) && return) unless (params[:q][:keyword].present? || !recruiters.blank?)

        # Search with Sunspot
        @jobs = Job.search(:include => [:addresses, :recruiter]) do

          paginate(:page => params[:page] || 1, :per_page => Constants::PAGE_SIZE)
          order_by(:created_at, :desc)
        
          unless recruiters.blank? 
            #recruiters = Employer.where("name like '%#{employer_name}%'").collect { |e| e.recruiters.collect {|r| r.id} }.flatten
            Rails.logger.debug("Recruiters:")
            Rails.logger.debug(recruiters.inspect)
            with(:recruiter_id).any_of(recruiters) 
          end

          unless params[:q][:keyword].blank?
            # Fix unclosed quotes
            query = params[:q][:keyword]
            query = query.delete('"') if query.count('"') % 2 > 0
            query = query.delete("'") if query.count("'") % 2 > 0
            keywords(query) {minimum_match 1}
          end

          # Filter by state if states are provided. 
          with(:state).any_of(([] << params[:q][:state]).flatten) unless params[:q][:state].to_s.blank?

          # Only display jobs posted or modified in the last month. 
  #        any_of {
  #          with(:created_at).greater_than(1.month.ago.to_date)
  #          with(:updated_at).greater_than(1.month.ago.to_date)
  #        }

          # Only active, not expired jobs
          with(:status).equal_to('active')
          with(:expires_at).greater_than(Date.today)

        end

#        unless @jobs.hits.blank? || @jobs.hits.empty? || !current_user || !current_user.linkedin_authenticated?
#          @connections = Connection.includes(:positions).where("applicant_id = #{current_user.id}").all
#          Rails.logger.debug(@connections.map{|c| [c.inspect, c.positions.map{|p| p.inspect}] });
#        end

    end


    def public_profile
        @job = Job.where(:code => params[:id].gsub("#2F#", "/")).first
        @job.employer.increment_job_views_stat unless @job.blank?
    end

    def show

        @job = Job.find(params[:id])
        @keyword = session[:keyword] || ""
        unless !current_user || !current_user.is_a?(Applicant) || !current_user.linkedin_authenticated?
          friends = Connection.includes(:positions).where("applicant_id = #{current_user.id}").all
          @connections = friends.select { |friend| 
            friend.positions.any?{ |p| !@job.employer.ticker_symbol.blank? && !p.ticker.blank? && p.ticker == @job.employer.ticker_symbol} 
          }
        end

        @job.employer.increment_job_views_stat

        # Sugest best resume matches
#        @matches = Resume.find_by_solr(
#          "#{@job.title.gsub(/[^A-Za-z1-9 ]/, " ")} AND (security_clearance:#{@job.security_clearance}) AND (education_level:#{@job.education_level})"
#        )

        require_applicant_menu if current_user && current_user.is_a?(Applicant)
        require_employer_menu if current_user && current_user.is_a?(Recruiter)

        render :layout => "application_full"

    rescue  ActiveRecord::RecordNotFound
        flash[:notice] = "Requested record does not exist."
        redirect_to jobs_path
    end

    def new
      (flash[:error] = "You don't have job posting privileges. Please contact <a href='mailto:#{UserMailer.admin_email}', style='color:#FFF;'>CGO Sales</a>" ) and redirect_to(jobs_path) if !current_user.employer.job_post_allowed?
      @job = Job.new()
      @address = Address.new(:label => "location")
    end


    def create

      @job = Job.new(params[:job].merge({:input_method => "manual"}))
      @address = Address.new(params[:address])

      @job.recruiter = current_user
      @job.expires_at = Time.now + Constants::DEFAULT_PUBLISH_PERIOD

      Job.transaction do
        @job.addresses << @address
        @job.save!
      end

      flash[:notice] = "Your changes have been saved"

      redirect_to job_path(@job.id)

    rescue ActiveRecord::ActiveRecordError
      @address.valid?
      render :action => "new"

    end

  
    def edit
      @job = current_user.jobs.find(params[:id])
      @address = @job.location
    end


    def update
      @job = current_user.jobs.find(params[:id])
      @address = @job.location
      Job.transaction do
        @job.update_attributes!(params[:job].merge({:input_method => "manual"}))
        @address.update_attributes!(params[:address])
      end

      flash[:notice] = "Your changes have been saved"
      redirect_to job_path(params[:id])

    rescue ActiveRecord::ActiveRecordError
      @address.valid?
      render :action => "edit"
    end
  
  
    def destroy
      @job = current_user.jobs.find(params[:id])
      @job.destroy if not @job.nil?

      flash[:notice] = "Job '#{@job.title}' (code: #{@job.code}) has been deleted"
      redirect_to jobs_path

    rescue ActiveRecord::ActiveRecordError => e
      flash[:notice] = "Unable to destroy: #{e.to_s}"
      redirect_to jobs_path
    end
  
  
    def repost
      job = current_user.jobs.find(params[:id])
      job.expires_at = Date::today + Constants::DEFAULT_PUBLISH_PERIOD
      job.save!

      flash[:notice] = "Success, Job '#{job.title}' will expire on #{(job.updated_at + 30.days).to_s(:long)}'"
      redirect_to job_path(job.id)

    rescue ActiveRecord::ActiveRecordError => e
      flash[:error] = "There was a problem re-posting your job. Please contact customer service"
      redirect_to job_path(job.id)
    end
  
  
    def apply
      @job = Job.find(params[:id])
      @applicant = current_user
      @applicant.apply(@job)
      @job.employer.increment_job_applicants_stat

      respond_to do |format|
        format.html{ flash[:notice] = "A message has been sent to the recruiter indicating your interest"; redirect_to job_path(@job.id) }
        format.xhr { render :json => @applicant.applications.to_json }
      end
    end

    # Called to notify that an applicant is applying with 
    # an externar URL. 
    def apply_notify

      @job = Job.find params[:id]
      @job.employer.increment_job_applicants_stat

      @applicant = current_user
      @applicant.apply(@job)

      respond_to do |format|
        format.xhr  { render :nothing => true }
        format.html { render :nothing => true }
      end

    end


    def add_to_inbox
      @job = Job.find params[:id]
      if not current_user.inbox_entries.find :first, :conditions => ["resource_id = ? AND resource_type = 'Job'", @job.id]
        current_user.inbox_entries << InboxEntry.new(:resource => @job, :added_by => "user")
      else
        render :nothing => true
      end

    rescue ActiveRecord::ActiveRecordError => e
      logger.error "UNABLE TO INSERT JOB IN USER #{current_user.username}'s INBOX: Error: #{e}"
    end

  
    def remove_from_inbox
      @entry = current_user.inbox_entries.find :first, :conditions => ["resource_id = ? AND resource_type = 'Job'", params[:id] ]
      if not @entry.nil?
        @entry.destroy 
      else
        render :nothing => true
      end
    end
  
end
