class Authentication < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :provider, :uid

  def self.new_from_linked_in auth_hash
      auth = Authentication.new(
        :provider => auth_hash["provider"], 
        :access_token => auth_hash["credentials"]["token"],
        :token_secret => auth_hash["credentials"]["secret"],
        :uid => auth_hash["uid"]
      )

      return auth
  end

  def generate_username 
    "#{provider}:#{uid}" unless provider.to_s.blank? || uid.to_s.blank?
  end
end
