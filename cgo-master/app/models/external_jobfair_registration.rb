class ExternalJobfairRegistration
  include Validatable

  validates_presence_of :company_name, :street_address, :city, :state, :zip
  validates_presence_of :contact_name, :phone, :fax, :email
  validates_presence_of :website, :description
  
  attr_accessor :company_name, :street_address, :city, :state, :zip
  attr_accessor :contact_name, :phone, :fax, :email
  attr_accessor :website, :description
  attr_accessor :electrical, :lunches, :directory_ad, :security_clearance

  def initialize(values={})

    @company_name = values[:company_name]
    @street_address = values[:street_address]
    @city = values[:city]
    @state = values[:state]
    @zip = values[:zip]

    @contact_name = values[:contact_name]
    @phone = values[:phone]
    @fax = values[:fax]
    @email = values[:email]

    @website = values[:website]
    @description = values[:description]

    @electrical = values[:electrical]
    @lunches = values[:lunches]
    @directory_ad = values[:directory_ad]
    @security_clearance = values[:security_clearance]

  end

end

