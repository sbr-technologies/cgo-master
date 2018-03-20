config.action_mailer.default_url_options = { :host => 'ipaddress' }
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  :address              => 'localhost',
  :port                 => 25,
  :domain               => 'corporategray.com',
  :user_name            => 'welcome',
  :password             => 'prius2004',
  :authentication       => :plain,
  :enable_starttls_auto => true,
  :openssl_verify_mode  => 'none'
}
