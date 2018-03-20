class JobApplicationObserver < ActiveRecord::Observer

  def after_create(job_application)

    # Notify Recruiters when applicants apply to their jobs
    message = Message.new(
      :body => "Job Seeker #{job_application.applicant.name} is interested in job: #{job_application.job.code}: #{job_application.job.title}",
      :action => "View Applicant",
      :action_url => "/applicants/#{job_application.applicant.id}"
    )
    job_application.job.recruiter.messages << message

    UserMailer.new_job_application(job_application).deliver
  end
end
