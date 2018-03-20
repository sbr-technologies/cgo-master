class Admin::ResumesController < ResumesController

  include ApplicationHelper

  # We don't need these methods here; Let's remove them for 
  # security's sake. 
#  remove_method :quick_search
#  remove_method :new
#  remove_method :create
#  remove_method :edit
#  remove_method :update
#  remove_method :print
#  remove_method :add_to_inbox
#  remove_methid :remove_from_inbox
#  remove_method :forward
#  remove_method :valid_attachment_extension?

  layout "admin/layouts/application"

  before_filter :login_required
  dont_require_role(:applicant_employer_admin_recruiter)
  dont_require_role(:employer_admin_recruiter)
  dont_require_role(:applicant) && dont_require_role(:recruiter) && dont_require_role(:employer_admin) && require_role(:admin)

  def index; end

  def search

    # Skip processing of empty queries
    return if params[:q].to_s.blank?


    @applicants = do_search(params[:page] || 1)

    if params[:is_download]

      applicants = []

      @applicants.results.each do |applicant| 
        applicants << applicant
      end

      page = 2
      while page < @applicants.results.total_pages
        @applicants = do_search(page)
        @applicants.results.each do |applicant|
          applicants << applicant
        end
        page = page + 1 
      end

      xml = Builder::XmlMarkup.new
      result = models_to_excel(xml, applicants, {
          :include => [
            "username", "status",
            "first_name", "last_name", "email",
            "education_level", 
            "security_clearance", 
            "type_of_applicant", 
            "willing_to_relocate", 
            "resume_posted_date",
            "state", 
            "city"
          ]
      })

      send_data(result, :filename => "search_results.xls", :type => "application/xls", :disposition => "inline");
      return
    end

  end


  private

  def do_search(page)
    
    # Fix unclosed quotes, and uppercase logical opperands.
    unless(params[:q][:keyword].to_s.blank?)
      query = params[:q][:keyword]
      query = query.delete('"') if query.count('"') % 2 > 0
      query = query.delete("'") if query.count("'") % 2 > 0
    end

    applicants = Applicant.search do

      paginate(:page => page, :per_page => Constants::PAGE_SIZE ) 
      order_by(:posted_date, :desc)

      if(query)
        keywords(query)
      else
        keywords(params[:q][:applicant_last_name].downcase, :fields =>[:last_name])
        #:with :last_name, params[:q][:applicant_last_name].downcase
      end

      with(:state).any_of(([] << params[:q][:state]).flatten) unless params[:q][:state].to_s.blank?

      with(:type_of_applicant).any_of(([] << params[:q][:type_of_applicant]).flatten) unless params[:q][:type_of_applicant].to_s.blank?
      with(:branch_of_service).any_of(([] << params[:q][:branch_of_service]).flatten) unless params[:q][:branch_of_service].to_s.blank?
      with(:security_clearance).any_of(([] << params[:q][:security_clearance]).flatten) unless params[:q][:security_clearance].to_s.blank?

      unless params[:q][:posted_date_for_solr].to_s.empty?
        how_many = (params[:q][:posted_date_for_solr] == "one-month" and 1) || (params[:q][:posted_date_for_solr] == "three-months" and 3) || 6
        with(:posted_sate_for_solr).between(how_many.months.ago.to_date.to_s(:yyyymmdd), Date.today.to_s(:yyyymmdd))
      end

      with(:willing_to_relocate).equal_to(params[:q][:willing_to_relocate]) unless params[:q][:willing_to_relocate].nil?

      job_fair_registrations = [params[:q][:job_fair_registrations]].flatten.compact 
      job_fair_registrations = job_fair_registrations.select { |jfr| !jfr.to_s.blank? }

      with(:job_fair_registrations).any_of(job_fair_registrations) unless job_fair_registrations.empty?

    end

    return applicants

  end

end
