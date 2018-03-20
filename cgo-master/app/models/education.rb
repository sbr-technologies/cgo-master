class Education < ActiveRecord::Base
  belongs_to :user

  validates :school_name, :presence => true

  attr_accessor :_delete

  def self.build_from_linkedin(data)
    
    educations = []

    data["values"].each do |edu| 

      startDate = edu["startDate"] || {}
      endDate = edu["endDate"] || {}

      educations.push Education.new(
        :school_name => edu["schoolName"],
        :field_of_study => edu["fieldOfStudy"],
        :degree => edu["degree"],
        :start_date =>  startDate["year"] || "",
        :end_date =>  endDate["year"] || "",
        :notes => edu["notes"] || "",
        :unique_identifier => "linked_in_#{edu['id']}"
      )
    end

    return educations

  end

end
