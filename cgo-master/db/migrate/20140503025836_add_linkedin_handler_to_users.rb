class AddLinkedinHandlerToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :linkedin_handler, :string
  end

  def self.down
    remove_column :users, :linkedin_handler, :string
  end
end
