require "zip/zipfilesystem"
require "rexml/document"
require 'xml/xslt'

module Paperclip
  class ExtractText < Paperclip::Processor

    def initialize(file, options = {}, attachment = nil)
						super
    end

				def make

						Rails.logger.debug("###### EXTRACT TEXT ######  extname: #{File.extname(file.path)}, content_type: #{attachment.content_type}")
						# Firefox sends mime: application/octet-stream, so we need to check for it AND the file extension. 
						if attachment.content_type == Mime::Type.lookup_by_extension("docx").to_s ||
									attachment.content_type == Mime::Type.lookup_by_extension("bin").to_s

								return process_docx

						elsif attachment.content_type == Mime::Type.lookup_by_extension("html").to_s
					
								return process_html
								
						end

				end

				private

				def process_docx

						Rails.logger.debug("In process_docx, file.path = #{file.path}, basename = #{File.basename(file.path, '.docx')}")
						dst = Tempfile.new([File.basename(file.path, ".docx"), options[:geometry]].compact.join("."))

						begin
						# .docx documents are really zip files; the content is located in the document 'word/document.xml'
						contents = Zip::ZipFile.open(file.path, "r").file.open("word/document.xml", "r")
      Rails.logger.debug("Opened Zip File and extracted document.xml")
						doc = REXML::Document.new contents

						if options[:geometry] == "txt"
								# in .docx spec, text nodes are <w:t>, we collect the text from them.
								txt = ""
								doc.elements.each("//w:t") { |el|
										dst.write(el.text.to_s + " ")
										txt += el.text.to_s + " "
								}
								attachment.instance.body = txt

						elsif options[:geometry] == "html"

								xslt = XML::XSLT.new()
								xslt.xml = doc
								xslt.xsl = "public/stylesheets/docx2html.xsl" 
								out = xslt.serve

								dst.write(out)

						end

      rescue Zip::ZipError => zip_error
        Rails.logger.error(zip_error.inspect)
        Rails.logger.error(zip_error.message)
						  attachment.instance.errors.add(:resume, "has an invalid format (is your resume saved in '.docx' format with MS Word 2003 or newer?)") if attachment.instance.errors.empty?

								raise PaperclipError, " is not readable; Please make sure you are uploading your resume in .docx format and that your file is not corrupt"

						rescue Exception => e

								# Only raise a new error if it's the first exception, otherwise we end up with duplicate errors.
								Rails.logger.error(e.message)
								Rails.logger.error(e.backtrace)
								raise PaperclipError, " is not readable; Please make sure you are uploading your resume in .docx format and that your file is not corrupt" if attachment.errors.empty?

						ensure
								return dst
						end


				end



				def process_html

						dst = Tempfile.new([File.basename(file.path, ".html"), options[:geometry]].compact.join("."))

						data = file.read
						file.rewind

						# nothing to do for HTML geometry
						if options[:geometry] == "html"
								dst.write(data)
								return dst
						end

						# extract text, save a txt file and set resume's body
						doc = REXML::Document.new("<div>" + data + "</div>")

						txt = []
						doc.root.elements.each("//") {|el|	txt.push el.text.to_s }
						dst.write(txt.join(" "))
						attachment.instance.body = txt.join(' ');

						dst

				end


		end
end
