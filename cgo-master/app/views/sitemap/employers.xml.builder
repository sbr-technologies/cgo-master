xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @employer_ids.each do |employer|
    xml.url do
      xml.loc public_profile_employer_url(employer.id)
      xml.lastmod Time.now.to_s(:yyyy_mm_dd)
    end
  end
end

