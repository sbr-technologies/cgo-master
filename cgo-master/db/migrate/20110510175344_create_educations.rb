class CreateEducations < ActiveRecord::Migration
  def self.up
    create_table :educations do |t|
      t.string :school_name
      t.string :field_of_study
      t.string :degree
      t.string :start_date
      t.string :end_date
      t.text   :notes

      t.integer :applicant_id
      t.string :unique_identifier

      t.timestamps
    end
  end

  def self.down
    drop_table :educations
  end
end
