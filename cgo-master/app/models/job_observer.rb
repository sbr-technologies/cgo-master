class JobObserver < ActiveRecord::Observer

  def before_save(job)
	job.status =  "inactive" if job.recruiter.nil?
  end
end
