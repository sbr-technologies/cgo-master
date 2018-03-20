class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.string  :category

      t.text    :body
      t.string  :action
      t.string  :action_url
      
      t.integer :recipient_id
      t.string  :recipient_type

						t.integer :sender_id
						t.integer :sender_type
      
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
