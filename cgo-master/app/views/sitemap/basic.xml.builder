xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @pages.each do |page|
    xml.url do
      xml.loc  page
      xml.lastmod Time.now.to_s(:yyyy_mm_dd)
    end
  end
end
