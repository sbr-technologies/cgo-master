class Seminar < ActiveRecord::Base
  belongs_to :jobfair
  
  validates_presence_of :description, :duration, :time
end
