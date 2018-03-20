class AddTwitterHandlerToEmployer < ActiveRecord::Migration
  def self.up
    add_column :employers, :twitter_handler, :string
  end

  def self.down
  end
end
