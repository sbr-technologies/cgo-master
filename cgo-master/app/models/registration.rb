class Registration < ActiveRecord::Base
  belongs_to :attendant, :polymorphic => true
  belongs_to :jobfair

  scope :for_employers, 
              :joins => "INNER JOIN users ON users.id = attendant_id and users.type = 'Recruiter'"

  scope :for_applicants, 
              :joins => "INNER JOIN users ON users.id = attendant_id and users.type = 'Applicant'"

  validates_presence_of :banner_company_name, :available_positions, :url, :lunches_required, :if => Proc.new { |reg| reg.attendant.is_a?(Recruiter) }
end
