class CreateRegistrations < ActiveRecord::Migration
  def self.up
    create_table :registrations do |t|

      # Attendant
      t.string   :attendant_type
      t.integer  :attendant_id
      t.integer  :jobfair_id

      #Employer Registration Fields
      t.integer	 :lunches_required
      t.string	 :available_positions
      t.boolean	 :include_in_employer_directory
      t.boolean	 :outlet_required
      t.boolean	 :paid
      t.string	 :banner_company_name
      t.string	 :fax
      t.string   :url
      t.string   :security_clearance
      t.boolean  :attending
      t.boolean  :enable_search
      t.string   :ad_type

      t.timestamps
    end
  end

  def self.down
    drop_table :registrations
  end
end
