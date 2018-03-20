class AlterJobsRelocationCostPaid < ActiveRecord::Migration
  def self.up
    change_column(:jobs, :relocation_cost_paid, :string)
  end

  def self.down
    change_column(:jobs, :relocation_cost_paid, :boolean)
  end
end
