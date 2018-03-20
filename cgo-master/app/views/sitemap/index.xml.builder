xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do

  @urls.each do |static_page_url|
    xml.url do
      xml.loc static_page_url[0]
      xml.lastmod static_page_url[1]
    end
  end

  @employer_ids.each do |employer|
    xml.url do
      xml.loc public_profile_employer_url(employer.id)
      xml.lastmod Time.now.to_s(:yyyy_mm_dd)
    end
  end

  @jobs.each do |job|
    xml.url do
      xml.loc  public_profile_job_url(job.code.gsub("/", "#2F#"))
      xml.lastmod job.updated_at.to_s(:yyyy_mm_dd)
    end
  end

end

