class UserObserver < ActiveRecord::Observer

  # Mail Activation and Signup Notifications emails.
  def after_create(user)

    UserMailer.deliver_signup_notification(user) unless user.activation_code.to_s.blank?   # !user.activation_code.nil? && !user.activation_code.empty?

	rescue  => err
      Rails.logger.error "Could not deliver email to #{user.username} with email: #{user.email}"
      Rails.logger.error err.backtrace.join("\n")
  end

  def after_save(user)
    UserMailer.deliver_activation(user) if user.recently_activated?
  end
end
