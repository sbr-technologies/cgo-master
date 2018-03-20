class CreateConnections < ActiveRecord::Migration
  def self.up
    create_table :connections do |t|
      t.string :provider
      t.string :unique_identifier
      t.string :first_name
      t.string :last_name
      t.string :company
      t.string :headline
      t.string :industry
      t.string :location
      t.string :profile_url

      t.string   :picture_url
      t.string   :photo_file_name
      t.string   :photo_content_type
      t.integer  :photo_file_size
      t.datetime :photo_updated_at

      t.integer :applicant_id

      t.timestamps
    end
  end

  def self.down
    drop_table :connections
  end
end
