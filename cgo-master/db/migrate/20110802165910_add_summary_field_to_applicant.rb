class AddSummaryFieldToApplicant < ActiveRecord::Migration
  def self.up
    add_column :users, :summary, :text
  end

  def self.down
    remove_column :users, :summary
  end
end
