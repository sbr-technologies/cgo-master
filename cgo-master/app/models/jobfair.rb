class Jobfair < ActiveRecord::Base
  
  has_many :seminars
  has_many :registrations

  validates_presence_of :category, :sponsor, :date, :start_time, :end_time, :fees, :city, :location
  validates_date        :date, :allow_nil => false
  validates_time        :start_time, :end_time
  validates_numericality_of :fees

  after_update :save_seminars
                      
  TYPES = ['military_friendly', 'security_clearance', 'diversity', 'junior_officer', 'virtual', 'Cyber Careers', 'military_officer', 'healthcare']
  SPONSORS = { :cgray => "Corporate Gray" }

  def self.first_upcoming
    # Requested by Carl: Skip jobfair #269 (MOAA on Nov 16th, show instead the next jobfair which is a CGO Sponsored one.
    Jobfair.find :first, :conditions => ["date >= ? AND id != 269 AND category != 'virtual'", Date.today], :order => "date ASC"
  end

  def self.all_upcoming
    Jobfair.find :all, :conditions => ["date >= ?", Date.today], :order => "date ASC"
  end

  def name
    "#{date.to_s(:human_long)} - #{location}"
  end

  def employer_registrations
    #registrations.select {|r| r.attendant.is_a?(Recruiter)}
    registrations.for_employers
  end

  def registered_applicants
    registrations.select {|r| r.attendant.is_a?(Applicant)}
    registrations.for_applicants
  end


  def new_seminar_attributes=(seminar_attributes)
    seminar_attributes.each do |attributes|
      seminars.build(attributes)
    end
  end

  def existing_seminar_attributes=(seminar_attributes)
      seminars.reject(&:new_record?).each do |seminar|
          attributes = seminar_attributes[seminar.id.to_s]
          if attributes
              seminar.attributes = attributes
          else
              seminars.delete(seminar)
          end
      end
  end

  def applicant_can_register?(applicant)
    if applicant.type == "Applicant"
      if self.category == 'military_officer'

        # Allowed Ranks for Miltiary Officer Jobfair: O-1, O-2, O-3, O-4, O-5, O-6, O-7, O-8, O-9, O-10, E-7, E-8, E-9, W-2, W-3, W-4, W-5
        allowed_ranks = ["10", "11", "12", "13", "27", "28", "29", "31", "32", "33", "34", "35", "5", "6", "7", "8", "9"]
        
        if(!allowed_ranks.include?(applicant.type_of_applicant))
          return false 
        end

      end
    end
    return true
  end

  def save_seminars
      seminars.each do |seminar|
          seminar.save(false)
      end
  end

end
