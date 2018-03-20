class Admin::EmployersController < EmployerController
  layout "admin/layouts/application"

  before_filter :login_required
  dont_require_role([:employer_admin, :recruiter]) && dont_require_role(:employer_admin) && dont_require_role(:recruiter) && require_role(:admin)
  before_filter :load_model, :except => ["index", "new", "create"]
  protect_from_forgery :except => "administrator_name"


  def index
    respond_to do |format|
      format.html {
        @employers = Employer.paginate :page =>params[:page] || 1, :order => "name", :include => ["recruiters"]
      }

      format.xls {
        Delayed::Job.enqueue(DownloadEmployersJob.new)
        flash[:notice] = "Your file is being prepared, you will be notified by email when is ready"
        redirect_to admin_employers_path
      }

      format.js {
        if !params[:q][:company_name].nil? && !params[:q][:company_name].empty?
            # Search by Company Name
            @employers = Employer.find :all,  :conditions => ["name LIKE ?",  "%#{params[:q][:company_name]}%"] , :order => "name"

        elsif !params[:q][:recruiter_name].nil? && !params[:q][:recruiter_name].empty?
            # Search by Recruiter Name
            @employers = Recruiter.find(:all, 
                :conditions => ["CONCAT(last_name, ', ', first_name) LIKE ?", "%#{params[:q][:recruiter_name]}%"], 
                :order => "last_name, first_name"
            ).collect {|x| x.employer }

        else
            @employers = Employer.find  :all, :order => "name"
        end

      }

    end
  end

  def show
  end


  def administrator_name 
    @employer = Employer.find params[:id]
    respond_to do |format|
      format.xhr { render :text => (@employer.administrator.name rescue "Not Specified") }
    end
  end


  def new
    @employer = Employer.new
    @employer.is_replace_all_on_import = true

    @recruiter = Recruiter.new
    @address = Address.new(:label => "primary")

    @valid_roles = %w(employer_admin)
  end

  def create

    @recruiter = Recruiter.new(params[:recruiter])
    @employer = (Employer.find(params[:recruiter][:employer_id]) if !params[:recruiter][:employer_id].blank?) || Employer.new(params[:employer])
      @address = Address.new(params[:address])

    Employer.transaction do

      @recruiter.add_role("employer_admin")
      @employer.save!

      @recruiter.status = "active"
      @recruiter.activation_code = nil
      @recruiter.activated_at = Time.now

      @employer.recruiters << @recruiter
      @recruiter.addresses << @address

    end

    render :action => :show

  rescue ActiveRecord::ActiveRecordError

    @recruiter.valid?
    @address.valid? 
    logger.error(@employer.errors.inspect)
    logger.error(@recruiter.errors.inspect)
    logger.error(@address.errors.inspect)
    render :action => "new"

  end




    def update

      @employer.update_attributes!(params[:employer]) unless @employer.nil?

          # Update Dates
#          @employer.job_postings_expire_at = (DateTime.civil(
#                                              params[:employer]["job_postings_expire_at(1i)"].to_i,
#                                              params[:employer]["job_postings_expire_at(2i)"].to_i,
#                                              params[:employer]["job_postings_expire_at(3i)"].to_i) rescue nil)
#
#          Rails.logger.debug("Job Postings expire at: #{@employer.job_postings_expire_at}")

#          @employer.resume_search_expire_at = (DateTime.civil(params[:employer]["resume_search_expire_at(1i)"].to_i,
#                  params[:employer]["resume_search_expire_at(2i)"].to_i,
#                  params[:employer]["resume_search_expire_at(3i)"].to_i) rescue nil)
#
#          Rails.logger.debug("Resume Search expire at: #{@employer.resume_search_expire_at}")

  #        Commented by Federico Jan 3, 2012: I don't think we are still using this. 
  #        And I don't see the fields to change the value of these fields in the form.
  #
  #        @employer.banner_option_start_at = (DateTime.civil(params[:employer]["banner_option_start_at(1i)"].to_i,
  #                params[:employer]["banner_option_start_at(2i)"].to_i,
  #                params[:employer]["banner_option_start_at(3i)"].to_i) rescue nil)
  #
  #        @employer.service_option_start_at = (DateTime.civil(params[:employer]["service_option_start_at(1i)"].to_i,
  #                params[:employer]["service_option_start_at(2i)"].to_i,
  #                params[:employer]["service_option_start_at(3i)"].to_i) rescue nil)


          # Update all attributes but dates. 
          #@employer.update_attributes!(params[:employer])

        flash[:notice] = "Your changes have been saved"
        redirect_to edit_admin_employer_path(@employer.id)

    rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.error e
        flash[:error] = e
        redirect_to edit_admin_employer_path(@employer.id)
    end


  protected


  def load_model
    @employer = Employer.find(params[:id])
  end
end
