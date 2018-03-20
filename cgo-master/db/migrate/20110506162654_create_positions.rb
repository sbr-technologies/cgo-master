class CreatePositions < ActiveRecord::Migration
  def self.up
    create_table :positions do |t|
      t.integer :employmenable_id
      t.string  :employmenable_type
      t.string :company
      t.string :industry
      t.string :title
      t.string :start_date
      t.string :end_date
      t.text :summary

      t.string :unique_identifier

      t.timestamps
    end
  end

  def self.down
    drop_table :positions
  end
end
