class CreateEmployers < ActiveRecord::Migration
  def self.up
    create_table :employers do |t|
      
      t.string    :name
      t.text      :profile
      t.text      :comments
      t.string    :website
      t.boolean   :is_federal_employer
      t.string    :referal_source
      
      t.integer   :max_recruiters, :null => false, :default => 10
      
      t.integer   :number_job_postings_remaining
      t.datetime  :job_postings_expire_at
      
      t.integer   :number_resume_searches_remaining
      t.datetime  :resume_search_expire_at
      
      t.integer   :number_trial_resume_searches_remaining
      t.datetime  :trial_resume_search_expire_at
      
      t.boolean   :is_replace_all_on_import
      t.boolean   :is_notify_job_postings
      
      t.string    :banner_option
      t.datetime  :banner_option_start_at
      
      t.string    :service_option
      t.datetime  :service_option_start_at
      
      t.integer   :sales_person_id

			t.string	  :track_image_url
      
      t.timestamps
    end
  end

  def self.down
    drop_table :employers
  end
end
