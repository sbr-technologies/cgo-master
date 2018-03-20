require "jobs_import_job.rb"

namespace :cron do

  desc "Create a Delayed Job to batch load FTP jobs" 
  task :load_jobs => :environment do
    # Notify Administrator of new Job Import
    Administrator.root_admin.messages << Message.new(
      :body => "Job Import process run on #{Date.today.to_s(:human)}"
    )
    Delayed::Job.enqueue JobsImportJob.new
  end
end
