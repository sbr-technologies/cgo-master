# require "google_docs_upload_job"

class ResumeObserver < ActiveRecord::Observer

  def after_save(resume)
    unless resume.attached_resume.original_filename.nil? || resume.attached_resume.content_type == "text/plain"
        # resume.applicant.solr_index   # Update Solr index.
        #Delayed::Job.enqueue GoogleDocsUploadJob.new(resume) 
    end
  end

end
