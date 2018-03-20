class AddJobApplicantsToEmployerStats < ActiveRecord::Migration
  def self.up
    add_column :employer_stats, :job_applicants, :integer, :default => 0
  end

  def self.down
    remove_column :employer_stats, :job_applicants
  end
end
