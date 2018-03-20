# Be sure to restart your server when you modify this file.

Cgray::Application.config.session_store :cookie_store, :key => '_cgray_session'

Cgray::Application.config.action_controller.session = {
    :session_key => '_cgray_session',
    :secret      => '8aeae86176bfe2585e8fbb03c2ee186a4282fb9994684b0b2f517ec65bdb2ac2545e0c705e65270866d3289099027a7946a95245c586ec49fe2b606ef11ff7cf'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
Cgray::Application.config.session_store :active_record_store
 
