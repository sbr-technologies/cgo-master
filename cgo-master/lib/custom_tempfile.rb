require "tempfile"

class CustomTempfile < ::Tempfile

  def initialize filename, tmpdir= Dir::tmpdir
    super
    @original_filename = File.basename(filename)
    @content_type = Mime::Type.lookup_by_extension(File.extname(filename)[1,4]).to_s
  end
  
  def original_filename
    @original_filename
  end

  def content_type
    @content_type
  end

end

