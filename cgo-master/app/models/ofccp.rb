class Ofccp < ActiveRecord::Base
				set_table_name "ofccp"

				belongs_to :employer

				def self.log(employer_id, job_code, query_string, applicant, recruiter)

								employer = Employer.find employer_id
								unless employer.nil?

												job = Job.find_by_code job_code, :limit => 1

              
              resume_text = ""

              if File.exist?(applicant.resume.attached_resume.path(:txt))
                resume_text = File.read(applicant.resume.attached_resume.path(:txt))

              elsif File.exist?(applicant.resume.attached_resume.path(:html))
                resume_text = File.read(applicant.resume.attached_resume.path(:html))

              else
                resume_text = "Not available in Paper Form"
              end


												ofccp_entry = Ofccp.new(
																:query_string										       => query_string,
																:job_code												         => job_code,
																:job_title											         => (job.title rescue "UNSPECIFIED"),
																:job_description								      => (job.description rescue "UNSPECIFIED"),
																:applicant_name									      => applicant.name,
																:applicant_modification_date  => applicant.updated_at || applicant.created_at,
																:applicant_ethnicity						    => applicant.ethnicity,
																:applicant_gender								     => applicant.gender,
																:resume_post_date								     => applicant.resume.posted_date,
                :resume													          => resume_text,
																:employer_name									       => recruiter.employer.name,
																:recruiter_name									      => recruiter.name,
																:recruiter_email								      => recruiter.email
												)

												employer.ofccp  << ofccp_entry
								end

				rescue ActiveRecord::ActiveRecordError => e
								logger.error(e)
    
				end
end
