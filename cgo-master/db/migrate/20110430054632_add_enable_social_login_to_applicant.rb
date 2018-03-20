class AddEnableSocialLoginToApplicant < ActiveRecord::Migration
  def self.up
    add_column :users, :social_login_enabled, :boolean, :default => 1
  end

  def self.down
    remove_column :users, :social_login_enabled
  end
end
