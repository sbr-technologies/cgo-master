class CreateInboxEntries < ActiveRecord::Migration
  def self.up
    create_table :inbox_entries do |t|

	t.integer	:user_id

	t.integer	:resource_id
	t.string	:resource_type

	t.string	:added_by, :default => "user"
	t.string	:status

	t.timestamps
    end
  end

  def self.down
    drop_table :inbox_entries
  end
end
