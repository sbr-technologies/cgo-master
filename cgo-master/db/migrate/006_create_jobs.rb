class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|

      t.string	  :status, :default => "active"
      t.string    :code
      t.string    :title, :null => false
      t.text      :description, :null => false
      t.string    :input_method
      t.text      :requirements
      
      t.datetime  :expires_at      
      
      t.string    :company_name   # replace by virtual method (get company name through recruiter)
      t.integer   :recruiter_id
      
      t.string    :education_level
      t.boolean   :experience_required
      t.string    :payrate
      t.string    :hr_website_url
      t.string    :online_application_url
      t.string    :security_clearance
      t.string    :travel_requirements
      
      t.boolean   :relocation_cost_paid, :null => false, :default => 0
      t.boolean   :show_company_profile, :null => false, :default => 1

      t.timestamps
    end
    
    
  end

  def self.down
    drop_table :jobs
  end
end
