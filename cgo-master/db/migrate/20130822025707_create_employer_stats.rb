class CreateEmployerStats < ActiveRecord::Migration
  def self.up
    create_table :employer_stats do |t|
      t.integer :employer_id
      t.integer :profile_views, :default => 0
      t.integer :job_views,     :default => 0
      t.integer :banner_clicks, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :employer_stats
  end
end
