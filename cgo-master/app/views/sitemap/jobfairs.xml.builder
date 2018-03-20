xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @jobfairs.each do |jobfair|
    xml.url do
      xml.loc  jobfair_url(jobfair.id)
      xml.lastmod jobfair.updated_at.to_s(:yyyy_mm_dd)
    end
  end
end
