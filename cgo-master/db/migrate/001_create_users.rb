class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      
      t.string		:type
      
      # Common Attributes
      t.string		:username
      t.string		:password
      t.string		:status, :null => false, :default => "active"
      t.string		:roles

      t.string		:activation_code
      t.datetime	:activated_at
      
      t.datetime	:imported_at
      t.datetime	:deleted_at
      t.datetime	:last_login_at
      t.integer		:login_count, :null => false, :default => 0
      
      t.string 		:title
      t.string 		:first_name
      t.string 		:last_name
      t.string		:initial
      t.string		:email
      
      t.string		:source             # Source website (REA, ROA, CGO, etc)
      
      t.string		:remember_token
      t.datetime	:remember_token_expires_at
      
      t.timestamps
      
      # Applicant Attributes
      t.string 		:job_title
      t.string 		:ethnicity
      t.string 		:gender
      t.datetime 	:availability_date
      
      t.string 		:branch_of_service
      t.string 		:education_level
      t.string 		:occupational_preference
      t.string 		:security_clearance
      t.string		:type_of_applicant
      t.string 		:military_status
      t.boolean		:us_citizen
      t.boolean 	:willing_to_relocate
      
      # Rectuiter Attributes
      t.integer		:employer_id
    end
    
    # ADMINISTRATOR
    User.create(:username => "admin", :password => "test", :first_name => "CGO", :last_name => "Administrator", :roles => "admin", :status => "active")
  end

  def self.down
    drop_table :users
  end
end
