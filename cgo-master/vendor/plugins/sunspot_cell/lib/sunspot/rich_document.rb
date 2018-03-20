module Sunspot
  class RichDocument < RSolr::Message::Document
    include Enumerable

    def contains_attachment?
      @fields.each do |field|
        if field.name.to_s.include?("_attachment")
          return true
        end
      end
      return false
    end



    def add(connection)
      params = {
        :wt => :ruby
      }

      data = nil

      @fields.each do |f|
        if f.name.to_s.include?("_attachment") 
          # By Federico Kattan 06/9/2011: Fetch Paperclip's attached File if no method 'data' is present
          data = (f.value.data rescue f.value.path ? File.read(f.value.path) : "")
          params['fmap.content'] = f.name
          # By F.K. Tika-154 Workaround
          params['resource.name'] = f.value.original_file_name if f.value.respond_to?(:original_file_name) && !f.value.original_file_name.to_s.blank? # TIKA-154 Workaround
        else
          param_name = "literal.#{f.name.to_s}"
          params[param_name] = [] unless params.has_key?(param_name)
          params[param_name] << f.value
        end
        if f.attrs[:boost]
          params["boost.#{f.name.to_s}"] = f.attrs[:boost]
        end
      end

      solr_message = params
      connection.send('update/extract', solr_message, data)
    end
  end
end
