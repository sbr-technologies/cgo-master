class CreateJobfairs < ActiveRecord::Migration
  def self.up
    create_table :jobfairs do |t|

      t.string :category                        
      t.string :sponsor                     
      
      t.date   :date
      t.string :start_time
      t.string :end_time
      
      t.integer :fees
      t.string  :city
      t.string  :location
      t.string  :location_url
      t.string  :recommended_hotel
      t.string  :recommended_hotel_url
      
      t.boolean :security_clearance_required               
      
      t.timestamps
    end

  end

  
  def self.down
    drop_table :jobfairs
  end
end
