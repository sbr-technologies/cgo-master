class AddCompanyTickerToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :ticker, :string
  end

  def self.down
    remove_column :positions, :ticker
  end
end
