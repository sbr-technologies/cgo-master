class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      
      # Label for this address i.e.: 'primary', 'work', 'record', 'notification', etc.
      t.string  :label, :default => "primary", :null => false
      
      t.integer :addressable_id
      t.string :addressable_type
      
      t.string :street_address1
      t.string :street_address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :email
      t.string :phone
      t.string :mobile
      t.string :fax
      t.string :website
      
      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
