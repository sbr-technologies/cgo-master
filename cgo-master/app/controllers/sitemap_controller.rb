class SitemapController < ApplicationController

  skip_before_filter :login_required

  @@static_skip = ["bnsf_hot_job.html.erb", "unisys_descriptions.html.erb", "general_dynamics.html.erb"]

  def index
    @urls = load_urls
    @jobfairs = Jobfair.all_upcoming
    @jobs = load_jobs
    @employer_ids = load_employers

    respond_to do |format|
      format.xml do
        headers["Last-Modified"] = Time.now.httpdate
      end
    end

  end

  def basic
    @pages = [root_url, employers_url, jobfairs_url]
  end


  def static
    @urls = load_urls
    respond_to do |format|
      format.xml do
        headers["Last-Modified"] = Time.now.httpdate
      end
    end
  end

  def jobfairs
    @jobfairs = Jobfair.all_upcoming
    headers["Last-Modified"] = Time.now.httpdate

    respond_to do |format|
      format.xml do
        headers["Last-Modified"] = Time.now.httpdate
      end
    end
  end


  def jobs
    @jobs = load_jobs
    respond_to do |format|
      format.xml do
        headers["Last-Modified"] = Time.now.httpdate
      end
    end
  end


  def employers
    @employer_ids = Employer.find_by_sql(
     "SELECT DISTINCT employers.id                                                        \
      FROM employers, users LEFT OUTER JOIN jobs ON (                                     \
          jobs.recruiter_id = users.id                                                    \
          AND users.type = 'Recruiter'                                                    \
          AND jobs.status = 'active'                                                      \
          AND DATE_FORMAT(jobs.expires_at, '%Y%m%d') > DATE_FORMAT(CURDATE(), '%Y%m%d'))  \
      WHERE jobs.id IS NOT null AND users.employer_id = employers.id"
    )

  end

  private

  def load_employers
    @employer_ids = Employer.find_by_sql(
     "SELECT DISTINCT employers.id                                                        \
      FROM employers, users LEFT OUTER JOIN jobs ON (                                     \
          jobs.recruiter_id = users.id                                                    \
          AND users.type = 'Recruiter'                                                    \
          AND jobs.status = 'active'                                                      \
          AND DATE_FORMAT(jobs.expires_at, '%Y%m%d') > DATE_FORMAT(CURDATE(), '%Y%m%d'))  \
      WHERE jobs.id IS NOT null AND users.employer_id = employers.id"
    )
  end
  def load_jobs
    @jobs = Job.find :all, :conditions => "status='active' AND expires_at > '#{2.weeks.from_now}'", :limit => 200, :order => "created_at DESC"
  end

  def load_urls
    Dir.chdir(File.join(Rails.root, "/app/views/static"))
    pages = Dir.glob("*.html.erb")

    urls = pages.collect { |page| 
      ["http://www.corporategray.com" + File.join("/static", File.basename(page, ".html.erb")), File.new(page).ctime.to_s(:yyyy_mm_dd)] unless @@static_skip.include?(page)
    }.compact

    return urls
  end

end
