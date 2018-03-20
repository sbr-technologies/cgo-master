class CreateAuthentications < ActiveRecord::Migration
  def self.up
    create_table :authentications do |t|

      t.string :provider
      t.string :uid
      t.string :access_token
      t.string :token_secret
      t.string :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :authentications
  end
end
