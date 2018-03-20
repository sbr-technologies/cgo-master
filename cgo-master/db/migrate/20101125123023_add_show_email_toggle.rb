class AddShowEmailToggle < ActiveRecord::Migration
  def self.up
    add_column :users, :is_display_email, :boolean, {:default => true}
  end

  def self.down
    remove_column :users, :is_display_email, :boolean
  end
end
