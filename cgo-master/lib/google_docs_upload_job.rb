require "docutil" 

class GoogleDocsUploadJob

  def initialize(resume)
    @resume_id = resume.id
  end

  def perform
    resume = Resume.find(@resume_id)

    unless resume.nil? || File.extname(resume.attached_resume.original_filename) == ".txt"
      ds = DocUtil::DocumentService.new
      
      # Delete previous documents from Google Docs if it exist
      doc_ids = ds.find("#{resume.id}_resume", false)
      unless doc_ids.to_s.blank?
        Delayed::Worker.logger.debug("About to delete: #{resume.id}_resume / #{doc_ids.inspect}")
        ds.delete(doc_ids) 
      else
        Delayed::Worker.logger.debug("No delete necesary; Nothing found with filename #{resume.id}_resume")
      end

      # Upload to Google Docs
      resource_id = ds.upload(
          "#{resume.id}_resume#{File.extname(resume.attached_resume.original_filename)}", 
          File.new(resume.attached_resume.path, "rb").read
      ) 
      
      Delayed::Worker.logger.debug("DOCUMENT CREATED (#{resource_id})")
      # Download .pdf and .html versions
      unless resource_id.to_s.blank? 
        File.open(resume.attached_resume.path("pdf"), "wb")  { |io| io.write ds.get(resource_id, :pdf) } unless File.extname(resume.attached_resume.original_filename) == ".pdf"
        File.open(resume.attached_resume.path("html"), "wb") { |io| io.write ds.get(resource_id, :html) }

        File.open(resume.attached_resume.path("txt"), "wb")  { |io| io.write ds.get(resource_id, :txt) }

      end

    end

  end

end
