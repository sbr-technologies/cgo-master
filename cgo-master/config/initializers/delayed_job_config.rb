#Delayed::Job.destroy_failed_jobs = false
#silence_warnings do
    #Delayed::Job.const_set("MAX_ATTEMPTS", 1)
    #Delayed::Job.const_set("MAX_RUN_TIME", 1.hours)
#end


Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 20
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 9.hours
#Delayed::Job.const_set("MAX_ATTEMPTS", 1)
#Delayed::Job.const_set("MAX_RUN_TIME", 8.hours)
#Delayed::Worker.logger = Rails.logger

Delayed::Worker.logger = ActiveSupport::BufferedLogger.new("log/#{Rails.env}_delayed_jobs.log", Rails.logger.level)
Delayed::Worker.logger.auto_flushing = 1

if caller.last =~ /.*\/script\/delayed_job:\d+$/
  ActiveRecord::Base.logger = Delayed::Worker.logger
end

require "builder"

