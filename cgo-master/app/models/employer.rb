class Employer < ActiveRecord::Base

    HUMANIZED_ATTRIBUTES = {
        :name => "Company Name"
    }

    def self.human_attribute_name(attr, options={})
        HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    end

    belongs_to :sales_person,
               :class_name => "User",
               :foreign_key => :sales_person_id
                          
    has_many :recruiters
    has_many :jobs, :through => :recruiters

    has_many :employer_stats

    # :through does not work with polymorphic associations
    # has_many :registrations, :through => :recruiters
    def registrations
      recruiters.collect {|recruiter| recruiter.registrations }.flatten
    end

    def delete_all_registrations
      recruiters.each do |recruiter|
        recruiter.registrations.delete_all
      end
    end

    has_many :ofccp

    validates_presence_of     :name, :profile, :website
    validates_presence_of     :sales_person_id        if @current_user && @current_user.has_role('admin')
    validates_uniqueness_of   :name, :on => :create

    DEFAULT_PROFILE_TEXT = "Company Profile Not Available"
  
    BANNER_OPTIONS = ["basic", "premium"]
    SERVICE_OPTIONS = ["basic", "premium"]

    REFERRAL_SOURCES = {
        :cgjobfair => "corporate gray military job fair",
        :cgbooks => "corporate gray series books",
        :dirctmail => "direct mail",
        :donna => "donna docherty",
        :email => "email promotion",
        :frmrmilt => "former military",
        :intsrch => "internet search",
        :melinda => "melinda engelbrektsson",
        :milttrans => "military transition office",
        :newsltr => "newsletter",
        :othrrecr => "other recruiters",
        :prvscomp => "used in previous company",
        :recruitersnetwork => "recruiters network",
        :staffingadvisors => "staffing advisors",
        :moaa => "military officers association of america",
        :washpost => "washington post",
        :other => "other",
    }


    def job_post_allowed?
        job_postings_expire_at > Time.now rescue false
    end

    def jobfair_search_allowed?
      (recruiters.collect {|recruiter| recruiter.registrations }.flatten.uniq.any? {|r| r.enable_search == true } rescue false)
    end

    def resume_search_privileges?
      (resume_search_expire_at > Time.now rescue false)
    end
  
    def resume_search_allowed?
      resume_search_privileges? || jobfair_search_allowed?
    end
  
    def trial?
        trial_resume_search_expire_at > Time.now rescue false
    end
    
    def administrator
        admin = recruiters.sort {|a,b| a.id <=> b.id}.detect {|user| user.has_role?('employer_admin')}
        admin ||= recruiters[0]  # ONLY While we fix data !!! Delete when done
    end

    def increment_profile_view_stat
      stats = get_current_date_stat_record
      stats.profile_views += 1
      stats.save!
    end

    def increment_job_views_stat
      stats = get_current_date_stat_record
      stats.job_views += 1
      stats.save!
    end

    def increment_job_applicants_stat
      stats = get_current_date_stat_record
      stats.job_applicants += 1
      stats.save!
    end

    def lifetime_profile_views
      lifetime_counter = 0
      self.employer_stats.each {|stat|
        lifetime_counter += stat.profile_views
      }
      return lifetime_counter
    end

    def lifetime_job_views
      lifetime_counter = 0
      self.employer_stats.each {|stat|
        lifetime_counter += stat.job_views
      }
      return lifetime_counter
    end

    def lifetime_job_applicants
      lifetime_counter = 0
      self.employer_stats.each {|stat|
        lifetime_counter += stat.job_applicants
      }
      return lifetime_counter
    end

    def get_stat_record(date)
      stat = self.employer_stats.where(["MONTH(created_at) = ? AND YEAR(created_at) = ?", date.month, date.year]).first()
      if !stat
        stat = EmployerStat.new({:employer_id => self.id})
      end

      return stat
    end

    def get_current_date_stat_record
      get_stat_record Date.today
    end
    
end
