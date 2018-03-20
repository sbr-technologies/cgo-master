require "gdata"
require "rexml/document"

module DocUtil

class DocumentService

  GDATA_PROTOCOL_VERSION = "3"
  VALID_EXPORT_FORMATS = [:doc, :html, :odt, :pdf, :png, :rtf, :txt, :zip]
  VALID_MIME_TYPES = ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "text/html"]

  # Only for client login
  USERNAME = "cgraydocs@gmail.com" 
  PASSWORD = "corpgray5581"


  def upload file_name, bytes, doc_id=nil

    mime_type = Mime::Type.lookup_by_extension(File.extname(file_name).gsub(".", "")).to_s
    raise ArgumentError, "Invalid Type specified: #{file_name} / #{mime_type}" unless VALID_MIME_TYPES.include?(mime_type)

    entry = new_entry(file_name, bytes, mime_type)

    client = get_client
    client.headers["Content-Type"] = "multipart/related; boundary=END_OF_PART"
    client.headers["Content-Length"] = entry.length

    # Update existing? or create new? 
    if doc_id.nil?
      response = client.post("https://docs.google.com/feeds/default/private/full", entry)
    else
      response = client.put("https://docs.google.com/feeds/default/media/document?#{doc_id}", entry)
    end

    if response.status_code == 201
      doc = REXML::Document.new response.body
      return doc.root.elements["gd:resourceId"].text.gsub(/^.*:/, "")
    else
      return "HTTP: #{response.status_code}"
    end

  end

  # Resource ids to delete, can be either a string or an array.
  def delete doc_id, etag="*"
    
    return false if doc_id.nil?

    client = get_client
    client.headers["If-Match"] = etag
    [*doc_id].each {|id|
       client.delete("https://docs.google.com/feeds/default/private/full/#{id}?delete=true")
    }

    return true

  end



  def find file_name, is_exact=true
    client = get_client
    url = "https://docs.google.com/feeds/default/private/full/-/document?title=#{CGI::escape(file_name)}&title-exact=#{is_exact}&showdeleted=false"

    response = client.get(url)

    if response.status_code == 200
      ids = (REXML::Document.new(response.body).root.elements.to_a("entry/gd:resourceId").map { |id| id.text.gsub(/^.*:/, "")  } rescue nil)
      return ids.empty? ? nil : ids
    end

    return nil

  end


  def get resource_id, format=:pdf

    raise ArgumentError, "Invalid format: #{format}, expecting one of #{VALID_EXPORT_FORMATS.join(", ")}" unless VALID_EXPORT_FORMATS.include?(format.to_sym)

    client = get_client
    
    # "Old-style" Get URL; see gdata-issues #2023, #2157
    response = client.get("https://docs.google.com/feeds/download/documents/Export?docID=#{resource_id}&exportFormat=#{format}")
    #response = client.get("https://docs.google.com/feeds/download/documents/export/Export?id=#{resource_id}&format=#{format}")

    if response.status_code == 200
      return response.body 
    else
      Rails.logger.debug("Error downloading format:#{format}: #{response.status.code}")
    end


    return nil

  end



  private


  def get_client
  
    client = GData::Client::DocList.new
    client.version = GDATA_PROTOCOL_VERSION
    
    # Uncomment for client login
    #client.clientlogin USERNAME, PASSWORD

    # Token must have been created through administration back-end (see WelcomeController)
    client.authsub_token = AuthsubToken.find(:first, :order => "created_at DESC").token

    return client

  end


  def new_entry title, bytes, mime_type

    raise ArgumentError, "Unsupported mime_type: #{mime_type}" unless VALID_MIME_TYPES.include?(mime_type)

    entry = <<-EOF
--END_OF_PART
Content-Type: application/atom+xml

<entry xmlns="http://www.w3.org/2005/Atom" xmlns:docs="http://schemas.google.com/docs/2007">
  <category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#document"/>
  <title>#{title}</title>
  <docs:writersCanInvite value="false" />
</entry>

--END_OF_PART
Content-Type: #{mime_type}

#{bytes}

--END_OF_PART--
    
EOF

    return entry

  end



end


end
