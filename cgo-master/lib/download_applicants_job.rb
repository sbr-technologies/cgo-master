class DownloadApplicantsJob

  include ApplicationHelper

  def initialize(jobfair_id=nil, status=nil)
    @jobfair_id = jobfair_id
    @status = status
  end

  def perform

    applicants = nil
    jobfair = nil
    filename = nil

    if !@jobfair_id.nil? && @jobfair_id != "-1"

        applicants = Jobfair.find(@jobfair_id).registrations.find(:all).collect {|r| r.attendant if r.attendant.is_a?(Applicant)}.compact
        if @status == "active" && !applicants.nil?
            applicants = applicants.select {|a| a.status == "active"}
        end

        jobfair = Jobfair.find @jobfair_id
        filename = "/mnt/outgoing/applicants_#{@jobfair_id.nil? ? '' : jobfair.location.gsub(/[\s;,.]/, '_') + '_' + jobfair.date.to_s(:default)}_#{Time.now.to_s(:tstamp)}_#{jobfair.id.to_s}.xls"

    else

        if @status.nil? || @status == "active"
            applicants = Applicant.find_all_by_status "active", :order => "first_name, last_name ASC"
        else
            applicants = Applicant.find :all, :order => "first_name, last_name ASC"
        end

        filename = "/mnt/outgoing/all_applicants_#{Time.now.to_s(:tstamp)}.xls"

    end

    result = ""
    unless applicants.to_s.blank?
      xml = Builder::XmlMarkup.new
      result = models_to_excel(xml, applicants, {
          :include => [
            "username", "status",
            "first_name", "last_name", "email",
            "education_level", 
            "security_clearance", 
            "type_of_applicant", 
            "branch_of_service",
            "willing_to_relocate", 
            "resume_posted_date",
            "state", 
            "city"
          ]
      })
    end

    ofile = File.open(filename, "w")
    ofile.write(result)
    ofile.close

    UserMailer.deliver_excel_file_ready(filename)

  end


end
