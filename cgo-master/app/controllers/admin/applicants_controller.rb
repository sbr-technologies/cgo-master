require "zip/zip"
require "zip/zipfilesystem"

class Admin::ApplicantsController < ApplicantController

  layout "admin/layouts/application"

  before_filter :login_required
  dont_require_role(:applicant_employer_admin_recruiter)
  dont_require_role(:applicant) && dont_require_role(:recruiter) && dont_require_role(:employer_admin) && require_role(:admin)

  before_filter :load_model, :except => ["index", "new", "create", "download_to_excel", "upload"]

  @@UPLOAD_DIRECTORY = "/mnt/incoming"

  def index

    respond_to do |format| 

      format.html {
        @applicants = Applicant.paginate :page =>params[:page] || 1, :per_page => 20, :order => "last_name, first_name"
      }

      format.js {
        if !params[:q][:name].empty?
          normalized_name = params[:q][:name].gsub(', ', ',');
          @applicants = Applicant.paginate :page => params[:page] || 1, :conditions => [ "CONCAT_WS(',', last_name, first_name) like ? ", "%#{normalized_name}%" ]

        elsif !params[:q][:email].empty?
          normalized_email = params[:q][:email].strip.downcase
          @applicants = Applicant.paginate :page => params[:page] || 1, :conditions => [ "LCASE(email) = ?", params[:q][:email] ]
        end

        render :template => "admin/applicants/index.js.erb"
      }

      format.xls {
        Delayed::Job.enqueue(DownloadApplicantsJob.new)
        flash[:notice] = "Your file is being prepared, you will be notified by email when is ready"
        redirect_to admin_applicants_path
      }

    end

  end

  def show
    @applicant = Applicant.find(params[:id])
  end

  def new
    @address = Address.new
    @applicant = Applicant.new
    @valid_roles = %w(applicant)
  end

  def update
    @applicant = Applicant.find(params[:id])

    unless @applicant.to_s.blank?
      Applicant.transaction do
        @applicant.update_attributes!(params[:applicant])
        @applicant.update_or_create_address(params[:address].merge({:label => "primary"}))
      end
    else
      flash[:error] = "An unexpected error occurred. Please try Again"
    end

    redirect_to admin_applicant_path(@applicant.id)

    rescue ActiveRecord::ActiveRecordError
      @address = @applicant.addresses[:primary]
      @address.valid?
      render :action => "edit"
  end


  def upload

    unless params[:headers_file] && params[:resumes_file]
      flash[:error] = "You must provide header and body files to upload" 
      redirect_to admin_applicants_path
      return 
    end

    @jobfair = Jobfair.find params[:jobfair]

    headers_filename = "headers_#{Time.now.to_s(:tstamp)}"
    headers_path = File.join(@@UPLOAD_DIRECTORY, headers_filename)
    File.open(headers_path, "wb") { |f| f.write(params[:headers_file].read) }

    resumes_filename = "resumes_#{Time.now.to_s(:tstamp)}"
    resumes_path = File.join(@@UPLOAD_DIRECTORY, resumes_filename)
    File.open(resumes_path, "wb") { |f| f.write(params[:resumes_file].read) }

    # Create new Job
    Delayed::Job.enqueue(ResumesUploadJob.new(@jobfair.id, headers_path, resumes_path))

    # Set flash and redirect to applicants index.
    flash[:notice] = "Header and Resume files, uploaded. You will receive email with the results of the upload process."
    redirect_to admin_applicants_path;
  end

  def download_to_excel
    Delayed::Job.enqueue(DownloadApplicantsJob.new(params[:jobfair], params[:status]))
    flash[:notice] = "Your file is being prepared, you will be notified by email when it becomes ready for download"
    redirect_to admin_applicants_path
  end


  private

  def load_model
    @applicant = Applicant.find params[:id]
  end

end
