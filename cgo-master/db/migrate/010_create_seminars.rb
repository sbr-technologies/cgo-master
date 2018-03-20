class CreateSeminars < ActiveRecord::Migration
  def self.up
    create_table :seminars do |t|
      t.string :description
      t.string :duration
      t.string :lcation
      t.string :time
      
      t.integer :jobfair_id

      t.timestamps
    end
  end

  def self.down
    drop_table :seminars
  end
end
