# To change this template, choose Tools | Templates
# and open the template in the editor.

class DownloadEmployersJob

		include ApplicationHelper


  def initialize
    
  end

		def perform

				xml = Builder::XmlMarkup.new
				employers = Employer.find :all, :order => "name"
	
				result = models_to_excel(xml, employers, {
								:include => [ "id", "name", "profile", "comments", "website", 
										"is_federal_employer", "referal_source", "max_recruiters", 
										"number_job_postings_remaining", "job_postings_expire_at", 
										"number_resume_searches_remaining", "resume_search_expire_at", 
										"number_trial_resume_searches_remaining", 
										"trial_resume_search_expire_at", "is_replace_all_on_import", 
										"is_notify_job_postings", "banner_option", 
										"banner_option_start_at", "service_option", 
										"service_option_start_at", "sales_person_id", "created_at", 
										"updated_at"]
						})

				filename = "/mnt/outgoing/employers_#{Time.now.to_s(:tstamp)}.xls"
				ofile = File.open(filename, "w")
				ofile.write(result)
				ofile.close

				UserMailer.deliver_excel_file_ready(filename)

		end



end
