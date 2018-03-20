class Recruiter < User

  belongs_to :employer
  has_many :jobs, :dependent => :destroy
  has_many :recruiter_stats, :dependent => :destroy

  validates_presence_of :employer_id
  # validates_presence_of :sales_person_id if @current_user && (@current_user.has_role?('admin') || @current_user.has_role?('sales_rep'))

  def register_for(jobfair, options = {})
    # Attendant should always be the"employer_admin" fallback to 
    # current_user if no administrator (until old accounts are 
    # fixed and folded into one)
    administrator = employer.administrator || self
    super(jobfair, options.merge({:attendant => administrator}))
  end

  def registered?(jobfair)
    employer.registrations.collect {|registration| registration.jobfair}.any? {|jf| jf.id == jobfair.id}
  end
  
  def increment_login_count_stat
    stat = get_current_date_stat_record
    stat.login_count = stat.login_count + 1
    stat.save
  end

  def increment_resume_views_stat
    stat = get_current_date_stat_record
    stat.resume_views = stat.resume_views + 1
    stat.save
  end

  def increment_resume_searches_stat
    stat = get_current_date_stat_record
    stat.resume_searches = stat.resume_searches + 1
    stat.save
  end

  private

  def get_current_date_stat_record
    today = Date.today
    stat = self.recruiter_stats.where(["MONTH(created_at) = ? AND YEAR(created_at) = ?", today.month, today.year]).first()
    if !stat
      stat = RecruiterStat.new({:recruiter_id => self.id}); 
    end

    return stat
  end

end
