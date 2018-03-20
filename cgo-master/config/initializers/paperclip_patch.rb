# I need to add a "data" method to Paperclip.Attachement
# this is required by sunspot_cell
module Paperclip
  class Attachment
    def data
      File.read(path)
    end
  end
end
