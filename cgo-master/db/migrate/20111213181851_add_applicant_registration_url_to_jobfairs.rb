class AddApplicantRegistrationUrlToJobfairs < ActiveRecord::Migration
  def self.up
    add_column :jobfairs, :applicant_external_registration_url, :string
  end

  def self.down
    remove_column :jobfairs, :applicant_external_registration_url
  end
end
