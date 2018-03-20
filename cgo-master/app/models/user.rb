require 'digest/sha1'
require "net/http"
require "uri"
require "social"

class User < ActiveRecord::Base

  @@linkedin_profile_api_url = "http://api.linkedin.com/v1/people/~" 

  has_many :authentications, :dependent => :destroy
  has_many :connections, :dependent => :destroy

  has_many :addresses, :as => :addressable, :dependent => :destroy do
    def [](label)
      find(:first, :conditions => ['label = ?', label.to_s.downcase]) rescue nil
    end
  end

  # Inbox entry can reference a resume or a job, depending on the kind of user
  has_many :inbox_entries do
    def contains?(resource, type="Resume")
      !resource.nil? && count(:conditions => ["resource_id = ? AND resource_type = ?", resource.id, type]) > 0
    end
  end
  
  # View in the Inbox / Dashboard and mainly populated by observers.
  has_many :messages, :as => :recipient, :dependent => :destroy, :order => "created_at DESC"
  has_one :message 

  has_many  :registrations, :as => :attendant, :dependent => :destroy, :order => "created_at DESC"
  
  validates_presence_of     :username,                   :if => :login_with_password?
  validates_uniqueness_of   :username,                   :if => :login_with_password?
  validates_length_of       :username, :within => 3..40, :if => :login_with_password?
  validates_presence_of     :password,                   :if => :login_with_password?
  validates_presence_of     :password_confirmation,      :if => :login_with_password?
  validates_length_of       :password, :within => 4..40, :if => :login_with_password?
  validates_confirmation_of :password,                   :if => :login_with_password?

  validates_presence_of     :first_name, :last_name
  validates_presence_of     :email, :if => :recruiter?

  STATUS = ["active", "inactive"]
  
  def login_with_password?
     authentications.to_s.blank?
  end

  def recruiter?
    has_role?("employer_admin") || has_role?("recruiter")
  end

  # ROLES 
  ROLES = [ 'admin', 'sales_rep', "employer_admin", "recruiter", "applicant" ]

  # Check the presence or arg in user's roles. Return true or false
  def has_role?(arg)    
    if arg.is_a?(Array)
      required_roles = arg.collect {|role| role.to_s}
    else
      required_roles = arg.to_s.to_a
    end
    not (self.roles.to_s.split(' ') & required_roles).empty?
  end
  
  # Add role to user's roles. Role should be one of User#ROLES
  def add_role(arg)
    raise ArgumentError, "Invalid role: '#{arg}' (expected one of User::ROLES [#{ROLES.join(', ')}])", caller if !ROLES.include?(arg)
    self.roles = "#{self.roles.to_s} #{arg}".strip if not has_role?(arg)
  end
  
  def remove_role(arg)
    self.roles = (self.roles.split(' ') - arg.to_a).join(' ') if has_role?(arg)
  end

	# Return "humanized" role names for the user
  def humanized_roles
    roles.split(' ').collect {|x| x.titleize}.join(", ")
  end

	# Return an array all site administrators
	def self.administrators
		User.find_by_sql 'select * from users where roles REGEXP "^admin.*|\sadmin.*";'
	end

	# Register for a jobfair. If the user is already registered ignore. This method is not meant
	# to be called directly, see: Applicant#register_for or Recruiter#register_for
	#
	# * Applicants don't have registration's extra information and options must be an empty hash.
	#
	# * Recruiters have additional information in the registration and the options parameter
	# contains the values from the registration form. Recruiter registrations should always be
	# added to the employer's administrator of the recruiter's company (see Reccruiter#register_for).
  def register_for(jobfair, options={})
    (Registration.new({:jobfair => jobfair, :attendant => self}.merge(options)).save!) && (return true) unless self.registered?(jobfair)
    return false

  rescue ActiveRecord::ActiveRecordError => e
    logger.error(e)
    return false
  end


  def update_or_create_address(hs)
    if addresses[hs["label"]].nil?
      addresses << Address.new(hs)
    else
      addresses[hs["label"]].update_attributes!(hs)
    end
  end

  # Virtual Attributes

  # Return complete name as string (title, first, initial, last)
  def name
    [first_name, initial, last_name].select {|x| not x.nil?}.map {|x| x.strip}.join(" ").titleize
  end
  
  def password_confirmation
    password
  end
  
  def is_active?
    status == "active"
  end
  
  def address
    addresses[:primary]
  end
  
  # --------------------------
  #      AUTHENTICATION
  # --------------------------

  # Authenticates a user by their username and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password)
    user = find_by_username_and_password_and_status_and_activation_code(username, password, "active", nil)

    unless user.nil? 
      user.login_count += 1
      user.last_login_at = Time.now 
      user.save 
    end

    return user
  end

  def encrypt(password, salt)
     Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  
  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end
  

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token = Digest::SHA1.hexdigest("#{email}--#{remember_token_expires_at}")
    save(:validate => false)
  end
  

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end


  # Activates the user in the database.
  def activate
    unless self.recently_activated?
      @activated = true
      self.activated_at = Time.now.utc
      self.activation_code = nil
      self.status = "active" if has_role?(:employer_admin) || has_role?(:applicant)
          
      save(:validate => false)
    end
  end

  def recently_activated?
    @activated
  end
  
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  def linkedin_authenticated?
    not self.authentications.find_by_provider("linked_in").nil?
  end

  def fetch_linkedin_profile(fields = ['first-name', 'last-name', 'headline'], access_token = nil, token_secret = nil)

    return if not linkedin_authenticated?

    if access_token == nil || token_secret == nil
      auth = self.authentications.find_by_provider("linked_in")
      access_token = auth.access_token unless auth.nil?
      token_secret = auth.token_secret unless auth.nil?
    end

    Social::LinkedIn.get(@@linkedin_profile_api_url + ":(#{fields.join(',')})", access_token, token_secret) unless access_token.blank?
  end

  def fetch_linkedin_photo

    return if not linkedin_authenticated?

    tmp_file = Tempfile.new("photo_#{id}_#{Time.now}")
    tmp_file.write(Net::HTTP.get(URI.parse(self.picture_url)))
    self.photo = tmp_file
    self.save!
  end

  def fetch_linkedin_connections

    return if not linkedin_authenticated?

    auth = self.authentications.find_by_provider("linked_in")
    raise "Unauthorized: Can't find linkedIn authorization for: #{username}:#{id} (#{name} / #{email})" if auth.nil?

    url="#{@@linkedin_profile_api_url}/connections:(id,first-name,last-name,headline,industry,location,picture-url,positions,api-standard-profile-request)"
    Rails.logger.debug("Fetching: " + url)
    results = Social::LinkedIn.get(url, auth.access_token, auth.token_secret)
    Rails.logger.debug(results.inspect)

    unless results.nil? || results.empty? 

      self.connections.destroy_all

      results["values"].each do |c| 
        connection = Connection.new(
          :provider => "linkedin",
          :unique_identifier => c["id"],
          :first_name => c["firstName"],
          :last_name => c["lastName"],
          :headline => c["headline"], 
          :industry => c["industry"],
          :location => (c["location"]["name"] rescue nil), 
          :profile_url => (c["apiStandardProfileRequest"]["url"] rescue nil),
          :picture_url => c["pictureUrl"]
        )
        unless c["positions"].nil? || c["positions"]["values"].nil?
          positions = []
          positions << c["positions"]["values"]
          positions.flatten.each do |p|
            if(p["is_current"] == "true" || p["is_current"] == true)
              position = Position.new(
                :unique_identifier => p["id"],
                :ticker            => p["company"]["ticker"],
                :company           => p["company"]["name"], 
                :industry          => p["company"]["industry"] || nil,
                :title             => p["title"]
              )
              connection.positions << position
            end
          end
        end
        
        self.connections << connection
      end
    end

    self.save!

  rescue Exception => e
    Rails.logger.error(e.inspect)
  end


  DEFAULT_PASSWORD_LENGTH = 6
   
  NUMBERS_AND_LETTERS_ALPHABET = [
    'A','B','C','D','E','F','G','H',
    'I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X',
    'Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n',
    'o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3',
    '4','5','6','7','8','9'
  ]
    
  def self.get_random_password
    self.generate_password(DEFAULT_PASSWORD_LENGTH)
  end 
    
    
  def self.generate_password(length) 
    password = []
    length.times do
      password.push NUMBERS_AND_LETTERS_ALPHABET[0 + rand(NUMBERS_AND_LETTERS_ALPHABET.size-1)];
    end 
        
    return password.to_s
  end 
  
end
