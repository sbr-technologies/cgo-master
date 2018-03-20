class AddTickerColumnToEmployer < ActiveRecord::Migration
  def self.up
    add_column :employers, :ticker_symbol, :string
  end

  def self.down
    remove_column :employers, :ticker_symbol
  end
end
