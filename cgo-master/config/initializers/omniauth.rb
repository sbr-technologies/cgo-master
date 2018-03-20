Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :facebook, 'CONSUMER_KEY', 'CONSUMER_SECRET'
  #provider :twitter, OAuthSecrets.providers[:twitter][:consumer_key], OAuthSecrets.providers[:twitter][:consumer_secret]
  provider :linkedIn, OAuthSecrets.providers[:linked_in][:consumer_key], OAuthSecrets.providers[:linked_in][:consumer_secret], :scope => "r_network"
end

