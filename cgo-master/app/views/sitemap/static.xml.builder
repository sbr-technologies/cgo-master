xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @urls.each do |static_page_url|
    xml.url do
      xml.loc static_page_url[0]
      xml.lastmod static_page_url[1]
    end
  end
end
