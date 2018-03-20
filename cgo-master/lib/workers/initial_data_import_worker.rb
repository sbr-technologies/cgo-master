# This worker is meant to be launched from a console session
# Make sure that you are working in the correct RAILS_ENV for the
# import (e.g. development, production, test).

require "mysql"

class InitialDataImportWorker < BackgrounDRb::MetaWorker

				set_worker_name :initial_data_import_worker

				def create(args = nil)
								# this method is called, when worker is loaded for the first time

								@now_d = Time.now
								@now = @now_d.strftime("%Y-%m-%d")

								# Database Parameters,  change in order to modify the source DB from where to import data.
								# @server = "localhost" # This is for testing
								@server = "data.corporategray.com" # For Production environment
								@db_user = "cgray_admin"
								@db_user_pw = "bmw325i"
								@db_name = "cgray"

				end


				def echo
								puts "Hello from InitialDataImportWorker"
				end

				def import_data

								logger.info "Commence data import on #{@now}"

								# connect to the MySQL server
								dbh = Mysql.real_connect(@server, @db_user, @db_user_pw, @db_name)
  
								# get server version string and display it
								logger.info "Connected. Server version: " + dbh.get_server_info


								# Import Administrators
								administrators = dbh.query("SELECT account.* FROM account, administrator WHERE acc_id = add_acc_id")
								administrators.each_hash do |row|
												account = new_account(row)
												account.roles = "admin"
												account.save!
								end
								administrators.free

								# Import Job Fairs
								jobfairs = dbh.query("SELECT job_fair.* FROM job_fair")

								logger.info "Number of Job Fairs to import: #{jobfairs.num_rows}"
    
								jobfairs.each_hash do |row|

												Jobfair.transaction do
																jobfair = new_jobfair(row)
																jobfair.save!
																for i in 1..6 do
																				if !row["jfa_seminar_desc#{i}"].nil? && !row["jfa_seminar_desc#{i}"].empty? && row["jfa_seminar_desc#{i}"] != ""
																								jobfair.seminars << new_seminar(row, i)
																				else
																								break
																				end
																end
												end

								end

								jobfairs.free
    

								# Import Applicants
								# Only Consider active applicants that logged in in the last year.

								applicants = dbh.query("
	SELECT account.*, applicant.*, address.*, resume.*, publishable.*
	FROM (account , applicant) 
	LEFT OUTER JOIN address ON acc_address = adr_id
	LEFT OUTER JOIN resume  ON app_resume = res_id 
	LEFT OUTER JOIN publishable ON app_resume = pub_id 
	WHERE acc_id = app_acc_id 
	AND   acc_status = 'active'
	AND   acc_last_login_date > '#{@now.to_date.years_ago(1).at_beginning_of_year.strftime("%Y-%m-%d")}'
												")

								logger.info "Number of Applicants to Import: #{applicants.num_rows}"

								applicants.each_hash do |row|

												begin
																Applicant.transaction do
																				applicant = new_applicant(row)
																				applicant.save!
																				applicant.addresses << new_address(row)

																				if !row["res_id"].nil? && !row["res_id"].empty? && row["res_id"] != ""
																								resume = new_resume(row)
																								applicant.resume = resume
																								resume.save!
																				end
																end
												rescue ActiveRecord::ActiveRecordError => e
																logger.error "Error while importing Applicant <#{row['acc_username']}: '#{row['acc_first_name']} #{row['acc_last_name']}' (#{row['adr_email']})>: #{e.inspect}"
												end

								end

								applicants.free

								# Import Employers. For each Employer we will create a new Employer Account and a Recruiter Account.
								employers = dbh.query("
	SELECT account.*, employer.*, address.*, admins.acc_username as admin_username
	FROM  (account, employer, address)
	LEFT OUTER JOIN account as admins ON admins.acc_id = employer.emp_sales_person
	WHERE account.acc_id = emp_acc_id
	AND   account.acc_address = adr_id	
	AND   account.acc_status='active'
												")

								logger.info "Number of Employers returned: #{employers.num_rows}"

								employers.each_hash do |row|

												begin
																Employer.transaction do
																				employer = new_employer(row)
																				employer.sales_person = (User.find_by_username(row["admin_username"]) rescue nil)
																				employer.save!

																				recruiter = new_recruiter(row)
																				recruiter.employer = employer
																				recruiter.roles =  "recruiter employer_admin"
																				recruiter.save!
																				recruiter.addresses << new_address(row)

																				# Import Employer's Jobs.
																				jobs = dbh.query("
		SELECT job.*, address.*, publishable.*
		FROM  publishable, job, address	
		WHERE pub_id = job_id	
		AND   job_employer = #{row['emp_acc_id']}
		AND   job_location = adr_id
		AND   pub_status = 'active'
		AND   pub_expiration_date > '#{@now}' 
																								")

																				logger.info "Number of Jobs to import for recruiter #{recruiter.username} : #{jobs.num_rows}"

																				jobs.each_hash do |job_row|
																								begin
																												Job.transaction do
																																job = new_job(job_row)
																																job.recruiter = recruiter
																																job.save!

																																location = new_address(job_row)
																																location.label = "location"
																																job.addresses << location

																																recruiter.jobs << job
																												end
																								rescue ActiveRecord::ActiveRecordError => job_e
																												logger.error "Job <#{job_row['job_code']}: #{job_row['job_title']}> Failed to load, Error " + job_e.inspect
																								end
																				end

																				jobs.free
																				employer.recruiters << recruiter
																end

												rescue ActiveRecord::ActiveRecordError => e
																logger.error "Error while Importing Employer <#{row['acc_username']}: '#{row['acc_first_name']} #{row['acc_last_name']}' (#{row['adr_email']})> :" + e.inspect
												end

								end
								employers.free

								logger.info("END OF LOAD !!!")

				rescue ActiveRecord::ActiveRecordError => e
								puts "Error in Active Error: #{e.inspect}"

				rescue Mysql::Error => e
								puts "Error code: #{e.errno}"
								puts "Error message: #{e.error}"
								puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")

				ensure
								# disconnect from server
								dbh.close if dbh
				end



				protected

				def new_jobfair(row)

								jobfair = Jobfair.new

								jobfair.date					= Date.parse row["jfa_date"]
								jobfair.start_time					= row["jfa_start_time"]
								jobfair.end_time					= row["jfa_end_time"]
								jobfair.fees					= row["jfa_fees"]
								jobfair.city					= row["jfa_city"]
								jobfair.location					= row["jfa_location"]
								jobfair.location_url				= row["jfa_location_url"]
								jobfair.recommended_hotel				= row["jfa_recommended_hotel"]
								jobfair.recommended_hotel_url			= row["jfa_recommended_hotel_url"]
								jobfair.security_clearance_required			= row["jfa_security_clearance_required"]
								jobfair.category					= row["jfa_type"]
								jobfair.sponsor					= row["jfa_sponsor"]

								return jobfair

				end


				def new_seminar(row, index)
    
								seminar = Seminar.new

								seminar.description					= row["jfa_seminar_desc#{index}"]
								seminar.duration					= row["jfa_seminar_duration#{index}"]
								seminar.time					= row["jfa_seminar_time#{index}"]

								return seminar

				end


				def new_account(row)
								user = User.new

								user.username					= row["acc_username"]
								user.password					= row["acc_password"]
								user.status						= row["acc_status"]
								user.activation_code				= nil
								user.activated_at					= @now
								user.imported_at					= nil
								user.deleted_at					= nil
								user.last_login_at					= row["acc_last_login_date"]
								user.login_count					= row["acc_login_count"]
								user.title						= row["acc_title"]
								user.first_name					= row["acc_first_name"]
								user.last_name					= row["acc_last_name"]
								user.initial					= row["acc_middle_initial"]
								user.email						= row["adr_email"]
								user.remember_token					= false
								user.remember_token_expires_at			= nil
								user.created_at					= row["acc_creation_date"]
								user.updated_at					= row["acc_modification_date"]

								return user
				end



				def new_employer(row)

								employer = Employer.new

								employer.name 					= row["emp_company_name"]
								employer.profile 					= (row["emp_company_profile"].nil? || row["emp_company_profile"].empty? ? "Company Profile Not Available" : row["emp_company_profile"])
								employer.comments					= row["emp_comments"]
								employer.website 					= row["emp_company_url"]
								employer.is_federal_employer 			= row["emp_federal_employer"]
								employer.referal_source 				= row["emp_referral_source"]
								employer.max_recruiters 				= 10
								employer.number_job_postings_remaining 		= row["emp_job_postings_remaining"]
								employer.job_postings_expire_at 			= row["emp_job_postings_expiration"]
								employer.number_resume_searches_remaining		= row["emp_resume_searches_remaining"]
								employer.resume_search_expire_at 			= row["emp_resume_searches_expiration"]
								employer.number_trial_resume_searches_remaining	= row["emp_trial_resume_searches_remaining"]
								employer.trial_resume_search_expire_at 		= row["emp_trial_resume_searches_expiration"]
								employer.is_replace_all_on_import			= row["emp_replace_all_on_import"]
								employer.is_notify_job_postings 			= row["emp_notify_job_postings"]
								employer.banner_option 				= row["emp_banner_option"]
								employer.banner_option_start_at 			= row["emp_banner_option_start_date"]
								employer.service_option 				= row["emp_service_option"]
								employer.service_option_start_at 			= row["emp_service_option_start_date"]

								return employer

				end


				def new_recruiter(row)

								recruiter= Recruiter.new

								recruiter.username					=  row["acc_username"]
								recruiter.password					=  row["acc_password"]
								recruiter.status 					=  row["acc_status"]
								recruiter.imported_at 				=  nil
								recruiter.deleted_at 				=  nil
								recruiter.last_login_at 				=  row["acc_last_login_date"]
								recruiter.login_count 				=  row["acc_login_count"]
								recruiter.title 					=  row["acc_title"]
								recruiter.first_name 				=  row["acc_first_name"]
								recruiter.last_name 				=  row["acc_last_name"]
								recruiter.initial					=  row["acc_middle_initial"]
								recruiter.email 					=  row["adr_email"]
								recruiter.source 					=  row["acc_source"]
								recruiter.remember_token 				=  nil
								recruiter.remember_token_expires_at 		=  nil
								recruiter.created_at 				=  row["acc_creation_date"]
								recruiter.updated_at 				=  row["acc_modification_date"]
								recruiter.activation_code				=  nil
								recruiter.activated_at 				=  @now

								return recruiter

				end

				def new_address(row)

								address  = Address.new(:label=>"primary")

								address.street_address1 				= row["adr_address1"]
								address.street_address2 				= row["adr_address2"]
								address.city            				= row["adr_city"]
								address.state           				= row["adr_state"]
								address.zip             				= row["adr_zip"]
								address.country         				= row["adr_country"]
								address.email           				= row["adr_email"]
								address.phone           				= row["adr_phone"]
								address.mobile          				= row["adr_mobile"]
								address.fax             				= row["adr_fax"]
								address.website         				= row["adr_website"]

								return address;
    
				end


				def new_applicant(row)

								applicant = Applicant.new
    
								applicant.username					= row["acc_username"]
								applicant.password					= row["acc_password"]
								applicant.status					= row["acc_status"]
								applicant.roles					= "applicant"
								applicant.imported_at				= row["acc_import_date"]
								applicant.deleted_at				= nil
								applicant.last_login_at				= row["acc_last_login_date"]
								applicant.login_count				= row["acc_login_count"]
								applicant.title					= row["acc_title"]
								applicant.first_name				= row["acc_first_name"]
								applicant.last_name					= row["acc_last_name"]
								applicant.initial					= row["acc_middle_initial"]
								applicant.email					= row["adr_email"]
								applicant.source					= row["acc_source"]
								applicant.remember_token				= nil
								applicant.remember_token_expires_at			= nil
								applicant.created_at				= row["acc_creation_date"]
								applicant.updated_at				= row["acc_modificaiton_date"]
								applicant.job_title					= row["app_job_title"]
								applicant.ethnicity					= row["app_ethnicity"]
								applicant.gender					= row["app_gender"]
								applicant.availability_date				= row["app_availability_date"]
								applicant.branch_of_service				= row["app_branch_of_service"]
								applicant.education_level				= row["app_education_level"]
								applicant.occupational_preference			= row["app_ocupational_preference"]
								applicant.security_clearance			= row["app_security_clearance"]
								applicant.type_of_applicant				= row["app_type_of_applicant"]
								applicant.military_status				= row["app_military_status"]
								applicant.us_citizen				= row["app_us_citizen"]
								applicant.willing_to_relocate			= row["app_willing_to_relocate"]
								applicant.activation_code				= nil
								applicant.activated_at				= @now

								return applicant

				end

				def new_resume(row)
    
								resume = Resume.new

								resume.visibility					= row["res_visibility"]
								resume.summary					= row["res_summary"]
								resume.body						= (row["res_resume"].nil? || row["res_resume"].empty? ? "EMPTY RESUME" : row["res_resume"])
								resume.created_at					= Date.parse(row["pub_creation_date"])
								resume.updated_at					= Date.parse(row["pub_modification_date"])

								return resume
				end


				def new_job(row)
								job = Job.new
    
								job.code						= row["job_code"]
								job.title						= row["job_title"]
								job.description					= row["job_description"]
								job.company_name                = row["job_company_name"]           if not row["job_company_name"].nil?
								job.education_level				= row["job_education_level"]
								job.experience_required			= row["job_experience_required"]
								job.payrate						= row["job_payrate"]
								job.hr_website_url				= row["job_hr_website_url"]
								job.online_application_url		= row["job_online_application_url"]
								job.relocation_cost_paid		= row["job_relocation_cost_paid"]
								job.requirements				= row["job_requirements"]
								job.security_clearance			= row["job_security_clearance"]
								job.show_company_profile		= row["job_show_company_profile"]
								job.travel_requirements			= row["job_travel_requirements"]
								job.created_at					= Date.parse(row['pub_creation_date'])
								job.updated_at					= Date.parse(row['pub_modification_date'])
    
								return job
				end

    
end

