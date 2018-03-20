class CreateRecruiterStats < ActiveRecord::Migration
  def self.up
    create_table :recruiter_stats do |t|

      t.integer :recruiter_id          
      t.integer :resume_views,    :default => 0
      t.integer :resume_searches, :default => 0
      t.integer :login_count,     :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :recruiter_stats
  end
end
