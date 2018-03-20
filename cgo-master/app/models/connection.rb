require "social"

class Connection < ActiveRecord::Base
  belongs_to :user
  has_many :positions, :as => :employmenable, :dependent => :destroy

#  has_attached_file :photo,
#    :url => "connections/:id/photo",
#    :path => ":rails_root/paperclip/:attachment/:id_photo.:content_type_extension",
#    :default_url => "/images/no_avatar.gif"

  validates_presence_of :provider, :unique_identifier, :first_name, :last_name 
end
