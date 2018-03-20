SELECT 
 pub_id as `id`, 
 job_code as `code`, 
 job_title as `title`, 
 job_description as `description`, 
 job_requirements as `requirements`, 
 pub_expiration_date as `expires_at`, 
 NULL as `company_name`, 
 emp_acc_id as `recruiter_id`, 
 job_education_level as `education_level`, 
 job_experience_required as `experience_required`, 
 job_payrate as `payrate`, 
 job_hr_website_url as `hr_website_url`, 
 job_online_application_url as `online_application_url`, 
 job_security_clearance as `security_clearance`, 
 job_travel_requirements as `travel_requirements`, 
 job_relocation_cost_paid as `relocation_cost_paid`, 
 job_show_company_profile+0 as `show_company_profile`, 
 pub_creation_date as `created_at`, 
 pub_modification_date as `updated_at`

FROM job, publishable, address, employer

WHERE pub_id = job_id
AND   adr_id = job_location
AND   emp_acc_id = job_employer
AND   pub_status = "active"
