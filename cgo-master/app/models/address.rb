class Address < ActiveRecord::Base

  belongs_to :addressable, :polymorphic => true

  attr_accessor :skip_validation
  
  # Three types of address records are allowed (discriminated by the "label" attribute): 
  # a) Type "primary" is a full record, includes address, city, state, zip, and relevant contact info (i.e. mobile, phone, etc)
  # b) Type "location" is a partial record and indicates only mailing address, with most fields optional.
  # c) Only for notification purposes, only email is required. 
  #
  # The validations below reflect the different record types and their validation rules. 
  # IMPORTANT: The DB should not do column validation (specifically not null columns) as this would 
  # override the rules here expressed. 
  validates_presence_of :country, :street_address1, :city, :state, :zip, :phone, :if => Proc.new { |address| address.label == "primary" && address.skip_validation.nil? }
  validates_format_of   :email , :with => Constants::EMAIL_PATTERN, :if => Proc.new { |address| !address.email.to_s.blank? }

  def city_state
    "#{city}, #{state}"
  end
end
