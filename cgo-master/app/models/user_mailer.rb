class UserMailer < ActionMailer::Base

  helper :application

  # Default Values
  #@@your_site = "localhost:3000"
  @@your_site = "www.corporategray.com"
  @@admin_email = "carl@corporategray.com"
  @@admin2_email = "corporategrayadmin@gmail.com"
  @@do_not_reply_email = "donotreply@corporategray.com"
  @@jobfair_admin_email = "barbara@corporategray.com"
  @@sales_email = "sales@corporategray.com"

  default :from => @@do_not_reply_email


  def self.your_site=(site)
    @@your_site = site
    logger.info("Setting User Mailer. website: #{@@your_site}")
  end

  def self.your_site
    @@your_site
  end

	
  def self.admin_email=(email)
    @@admin_email = email
    logger.info("Setting User Mailer. admin email: #{@@admin_email}")
  end

  def self.admin_email
    @@admin_email
  end


  def self.sales_email 
    @@sales_email
  end

  def signup_notification(user)
    setup_email
    recipients	"#{user.email}"
    from		"#{@@do_not_reply_email}"
    subject     "Please activate your new account"
    body		:url => "http://#{@@your_site}/activate/#{user.activation_code}", :user => user
  end
  
  def activation(user)
    setup_email
    recipients  "#{user.email}"
    from		"#{@@do_not_reply_email}"
    subject     'Your account has been activated!'
    body		 :url => "http://#{@@your_site}/", :user => user
  end

  def password_reminder(user)
    setup_email
    from		 "#{@@do_not_reply_email}"
    recipients	 "#{user.email}"
    subject		 "Your Corporate Gray Online Account Information"
    body		 :user => user
  end

  def new_message_notification(user)
    setup_email
    recipients	"#{user.email}"
    from		"#{@@do_not_reply_email}"
    subject     'You have new messages in Corporate Gray Online'
    body		:user => user
  end

  def new_employer_account_notification(user)
    setup_email(:text)
    recipients	"#{@@admin_email}, #{@@admin2_email}"
    from	    "#{@@do_not_reply_email}"
    subject		"New Employer Registration"
    body		:user => user
  end

  def new_employer_jobfair_registration(registration, recipients_list=nil)
    setup_email(:text)
    recipients	!recipients_list.nil? ? recipients_list.join(',') : "#{@@jobfair_admin_email}, #{@@admin_email}, #{@@admin2_email}"
    from		"#{@@do_not_reply_email}"
    subject		"New Jobfair Registration"
    body		:registration => registration
  end

  def new_applicant_jobfair_registration(registration, recipients_list)
    setup_email(:text)
    recipients	recipients_list.join(',') 
    from	    "#{@@do_not_reply_email}"
    subject	    "New Jobfair Registration"
    body		:registration => registration
  end


  def new_jobfair_registration_from_affiliate(registration, jobfair, recipients_list=nil)
    setup_email(:text)
    recipients	  !recipients_list.nil? ? recipients_list.join(',') : "#{@@jobfair_admin_email}, #{@@admin_email}, #{@@admin2_email}"
    from		 "#{@@do_not_reply_email}"
    subject		 "New Affiliate Jobfair Registration"
    body		 :registration => registration, :jobfair => jobfair
  end

  def new_job_application(job_application)
    setup_email
    recipients	job_application.job.recruiter.email
    from		"#{@@do_not_reply_email}"
    subject		"Candidate Interested in Your Position"
    body		:applicant => job_application.applicant, :job => job_application.job
  end

  def job_upload_with_errors_notification(employer_email, filename, errors)
    setup_email(:text)
    recipients	"#{employer_email}"
    bcc			"#{@@admin_email}"
    from		"#{@@do_not_reply_email}"
    subject		"Errors during Job Upload of #{filename}"
    body		:filename => filename, :errors => errors
  end


  def resumes_upload_complete_notification(jobfair, total_headers, total_resumes, total_created, total_updated, total_rejected, warnings, passw_filename)
    setup_email(:text)
    recipients	"#{@@jobfair_admin_email}, #{@@admin_email}, #{@@admin2_email}"
    from		"#{@@do_not_reply_email}"
    subject		"Upload Resumes for #{jobfair.name} Completed."
    body		:jobfair => jobfair,
                :total_headers => total_headers,
                :total_resumes => total_resumes,
                :total_created => total_created,
                :total_updated => total_updated,
                :total_rejected => total_rejected,
                :warnings => warnings,
                :passw_filename => passw_filename
  end


  def excel_file_ready(filename)
    setup_email(:text)
    recipients	"#{@@admin_email}, #{@@admin2_email}"
    from		"#{@@do_not_reply_email}"
    subject		"CGO Export: Your Excel File Is Ready"
    body		:filename => filename
  end

  def delayed_job_failed_notification(delayed_job)
    setup_email(:text)
    recipients	"#{@@jobfair_admin_email}, #{@@admin_email}, #{@@admin2_email}"
    from		"#{@@do_not_reply_email}"
    subject		"Job:#{delayed_job.id} Failed!"
    body		:delayed_job => delayed_job
  end


  def employer_does_not_have_job_posting_privileges_notification(filename, employer_name)
    setup_email(:text)
    recipients	"#{@@admin_email}"
    from		"#{@@do_not_reply_email}"
    subject		"No Job Post Privileges: Upload of #{filename} Failed"
    body		:filename => filename, :employer_name => employer_name
  end

  def employer_is_not_an_admin_notification(filename, recruiter)
    setup_email(:text)
    recipients	"#{@@admin_email}"
    from		"#{@@do_not_reply_email}"
    subject		"Wrong Recruiter Account: Upload of #{filename} Failed"
    body		:filename => filename, :recruiter => recruiter
  end

  def invalid_filename_in_ftp_folder(filename)
    setup_email(:text)
    recipients	"#{@@admin_email}"
    from		"#{@@do_not_reply_email}"
    subject		"UPLOAD ERROR: Can't find employer account for #{filename}"
    body		:filename => filename
  end

  def forward_resume(user, resume, recipients)

    @user = user
    @resume = resume

    resume_body, content_type = resume.get_body ["pdf", "doc", "docx", "txt"]
    ext = Mime::Type.lookup(content_type).to_sym.to_s
    filename = "#{resume.applicant.first_name}_#{resume.applicant.last_name}_resume"

    attachments["#{filename}.#{ext}"] = { 
      :content => resume_body, 
      :mime_type => content_type 
    }

    mail(
      :to => recipients.join(","),
      :subject => "Resume of #{resume.applicant.name}"
    )
 
  end


  
protected
  def setup_email(mime = :html)
    sent_on Time.now
    case mime
      when :html then content_type "text/html"
      when :text then	content_type "text/plain"
      else content_type "text/html"
    end
  end
end
