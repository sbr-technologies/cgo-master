class AddRecruiterResumeStatistics < ActiveRecord::Migration
  def self.up
    add_column :users, :last_resume_search_date, :datetime
    add_column :users, :count_resume_searches, :integer, :default => 0
    add_column :users, :count_resume_views, :integer, :default => 0
  end

  def self.down
    remove_column :users, :last_resume_search_date, :datetime
    remove_column :users, :count_resume_searches, :integer
    remove_column :users, :count_resume_views, :integer
  end
end
