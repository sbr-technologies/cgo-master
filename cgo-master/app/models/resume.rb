class Resume < ActiveRecord::Base

  Resume::VISIBILITY = ['public', 'private', 'confidential']

  belongs_to :applicant

  has_many :inbox_entries, :as => :resource
	
  # :url  => "attachments/:attachment/:id_resume.:content_type_extension"
  has_attached_file	:attached_resume,
    :path => ":rails_root/paperclip/:attachment/:id_resume.:content_type_extension",
    :url  => ":id/attachment.:content_type_extension"

  validates_attachment_presence	:attached_resume, 
    :if => lambda { |res| res.input_method == "upload"}, 
    :message => ".You must select a file to upload"

  validates_attachment_size	:attached_resume, :less_than => 512.kilobytes


  def normalized_filename

  end


  def data
    filename = self.attached_resume.path || (self.attached_resume.queued_for_write[:original].path rescue nil)
    (filename ?  File.read(filename) : "")
  end

  def posted_date
    (updated_at || created_at).to_date
  end

  def posted_date_for_solr
    posted_date.to_s(:yyyymmdd)
  end

  def posted_months_ago
    tstamp = posted_date
    if tstamp >= 1.month.ago.to_date
      return "one-month"
    elsif tstamp >= 3.month.ago.to_date
      return "three-months"
    elsif tstamp >= 6.month.ago.to_date
      return "six-months"
    end
    return "over-six-months"
  end


  # Deprecated: This method is not being used, it can be deleted. 
  # This is also incorrect since it does not account for .doc file type. 
  # Action: Comment and delete if no side-effects. 
  # def current_text_format
    # (attached_resume.path(:docx) && :docx) || (attached_resume.path(:html) && :html) || :text
  # end

  def has_body? format
    formats = [].push(format).flatten
    formats.any? { |fmt| File.exists?(attached_resume.path(fmt)) }
  end

  def get_body format=nil

    resume_body, content_type = nil
    formats = [].push(format || ["pdf","doc", "docx", "html", "txt"]).flatten
    formats.each do |fmt|
      if File.exists?(attached_resume.path(fmt))
        resume_body = File.read(attached_resume.path(fmt))
        content_type = Mime::Type.lookup_by_extension(fmt).to_s
        break
      end
    end
    return [resume_body, content_type]

  end


  def formatted_text(fmt=:web)

    if(fmt == :web)

      if !attached_resume.path(:html).nil? && File.exist?(attached_resume.path(:html))
        File.open(attached_resume.path(:html), "r").read
      else attached_resume.path(:txt).nil? && File.exit?(attached_resume.path(:txt))
        File.open(attached_resume.path(:txt), "r").read.gsub(/[\r\n]{1,2}/, "<br/>")
      end

    elsif fmt == :text && attached_resume.path(:txt).nil? && File.exit?(attached_resume.path(:txt))
      File.open(attached_resume.path(:txt), "r").read.gsub(/[\r\n]{1,2}/, "<br/>")
    end

  end

end
