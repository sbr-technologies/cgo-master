class Position < ActiveRecord::Base

  belongs_to :employmenable, :polymorphic => true

  validates :company, :presence => true
  validates :title, :presence => true
  
  attr_accessor "_delete"

  def self.build_from_linkedin(data)
    
    positions = []

    data["values"].each do |pos| 

      startDate = pos["startDate"] || {}
      endDate = pos["endDate"] || {}

      positions.push Position.new(
        :company => pos["company"]["name"],
        :industry => pos["company"]["industry"],
        :title => pos["title"],
        :summary => pos["summary"],
        :start_date =>  startDate["year"] || "",
        :end_date =>  endDate["year"] || "",
        :unique_identifier => "linked_in_#{pos['id']}"
      )
    end

    return positions

  end

end
