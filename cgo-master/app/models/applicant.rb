class Applicant < User
  
  has_one   :resume

  has_many  :job_applications,
            :dependent => :destroy,
            :order => "created_at DESC"

  has_many  :positions, :as => :employmenable, :order => 'start_date desc'
  has_many  :educations, :order => 'start_date desc'
  has_many  :connections

  searchable do
    string  :status
    text    :first_name, :as => :first_name_textp
    text    :last_name, :as => :last_name_textp
    text    :title
    text    :summary
    string  :email
    text    :title
    time    :availability_date
    integer :education_level
    integer :branch_of_service
    integer :security_clearance
    integer :occupational_preference
    integer :type_of_applicant
    boolean :willing_to_relocate
    boolean :us_citizen

    # Resume Fields
    text :summary

    string :resume_visibility do
      resume ? resume.visibility : nil
    end

    time :posted_date do
      resume ? (resume.updated_at || resume.created_at).to_date : nil
    end

    attachment :attached_resume

    # Job Fair Registrations
    integer :job_fair_registrations, :multiple => true do
      registrations.collect(&:jobfair_id)
    end

    # Positions
    # (text fields accepts an array of text)
    text  :position_title do
      positions.collect(&:title)
    end

    text :work_experience do
      positions.collect(&:summary)
    end

    # Primary Address: State
    string :state do
      addresses[:primary].state unless addresses.nil? || addresses[:primary].nil?
    end

  end

  validates_presence_of :branch_of_service, :type_of_applicant, :security_clearance, :education_level, :occupational_preference

  accepts_nested_attributes_for :positions, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :educations, :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :resume, :allow_destroy => true, :reject_if => :all_blank

  def attached_resume
    resume ? resume.attached_resume : Resume.new(:visibility => :public).attached_resume
  end

  def applied?(job)
    job_applications.any? {|application| (application.job.id == job.id rescue false) } 
  end

  def apply(job)
    unless self.applied?(job)
      Applicant.transaction do
        application = JobApplication.new
        application.job = job
        self.job_applications << application
      end
    end
  end

  def register_for(jobfair, options={})
    retval = super(jobfair, options)

    # Update solr Index
    resume.save! unless resume.nil?

    return retval
  end

  def registered?(jobfair)
    registrations.any? {|reg| reg.jobfair.id == jobfair.id}
  end

  # ------------------------------------
  # Needed for download to excel export. 
  # ------------------------------------
  def state
    address.state
  end

  def city
    address.city
  end

  def resume_posted_date
    resume.posted_date
  end
  
  # ------------------------------------

private

#  def linkedin_get(url, access_token, token_secret)
#
#    consumer = OAuth::Consumer.new(OAuthSecrets.providers[:linked_in][:consumer_key], OAuthSecrets.providers[:linked_in][:consumer_secret])
#    handler = OAuth::AccessToken.new(consumer, access_token, token_secret) unless consumer.nil?
#
#    if handler
#      json_txt = handler.get(url, 'x-li-format' => 'json').body
#    end
#
#    return json_txt.blank? ? nil : JSON.parse(json_txt)
#  end

end
