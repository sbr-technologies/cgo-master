class Administrator < User

  ADMIN_USER = "administrator"

  NOTIFICATIONS = {
    :new_job_seeker_jobfair_regisration => [ADMIN_USER],
    :new_recruiter_jobfair_registration => [ADMIN_USER],
    :new_recruiter_account		=> [ADMIN_USER]
  }

  def self.root_admin
    User.find :first, :conditions => ["username = ?", ADMIN_USER]
  end

end