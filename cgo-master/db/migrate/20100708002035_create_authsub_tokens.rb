class CreateAuthsubTokens < ActiveRecord::Migration
  def self.up
    create_table :authsub_tokens do |t|
      t.string :token

      t.timestamps
    end
  end

  def self.down
    drop_table :authsub_tokens
  end
end
