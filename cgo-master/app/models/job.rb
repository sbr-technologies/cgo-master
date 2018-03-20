require "nokogiri" 

class Job < ActiveRecord::Base

  searchable do
    text   :title, :boost => 4.0
    text   :body 
    string :state
    string :status
    date   :created_at
    date   :updated_at
    date   :expires_at
    integer :recruiter_id
  end
   
  belongs_to :recruiter
  
  has_many :addresses, :as => :addressable, :dependent => :destroy do
    def [](label)
      find(:first, :conditions => ['label = ?', label.to_s.downcase])
    rescue
      nil
    end
  end
  
  has_many  :job_applications, :dependent => :destroy, :order => "created_at DESC"

  has_many :inbox_entries, :as => :resource, :dependent => :destroy
  
  validates_presence_of :code, :title, :description, :education_level
  

  def active?
    status == "active"
  end

  def expired? 
    Time.now.at_beginning_of_day > expires_at.at_beginning_of_day
  end
  
  def employer
    recruiter.employer rescue nil
  end
  
  # This is masking the DB's field 'company_name'
  # DISABLED by Fede Jan 10, 2008 to display
  # the real employer for jobs loaded by job wrappers (i.e. JobCentral)
  #
  #def company_name
  #  recruiter.employer.name
  #end
  
  def location
    # If "addresses" was eager loaded; then search for the "location" address. Otherwise
    # do a scoped find. 
    if addresses.length > 0
      addresses.select {|a| a.label == "location"}[0]
    else
      addresses[:location]
    end
  end

  def location=(location)
    location.label = "location"
    addresses << location
  end

  def state 
    addresses[:location].state.strip rescue "0"
  end

  # Extract text from HTML fragment. 
  def body
    doc = Nokogiri.parse("<html><body>#{description}</body></html>")
    return doc.text
  end

  def posted_months_ago

    tstamp = (updated_at || created_at).to_date

    if tstamp >= 1.month.ago.to_date
        return "one-month"

    elsif tstamp >= 3.month.ago.to_date
        return "three-months"

    elsif tstamp >= 6.month.ago.to_date
        return "six-months"
    end

    return "over-six-months"
      
  end
    
end
