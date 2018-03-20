# To change this template, choose Tools | Templates
# and open the template in the editor.

class DelayedJobObserver < ActiveRecord::Observer

		observe Delayed::Job

		def after_update(delayed_job)
				unless delayed_job.failed_at.nil?
						UserMailer.delayed_job_failed_notification(delayed_job).deliver
				end
  end
end
