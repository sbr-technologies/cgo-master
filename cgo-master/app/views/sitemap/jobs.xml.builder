xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @jobs.each do |job|
    xml.url do
      xml.loc  public_profile_job_url(job.code)
      xml.lastmod job.updated_at.to_s(:yyyy_mm_dd)
    end
  end
end
