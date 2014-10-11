# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.dancercity.net"

SitemapGenerator::Sitemap.create do
  add about_path, :lastmod => Time.now, :priority => 0.9, :changefreq => 'weekly'
  add privacy_path, :lastmod => Time.now, :priority => 0.7, :changefreq => 'monthly'
  add terms_path, :lastmod => Time.now, :priority => 0.7, :changefreq => 'monthly'

  Post.find_each do |post|
    add post_path(post), :lastmod => post.updated_at, :priority => 0.8, :changefreq => 'weekly', :news => {
          :publication_name => "Dancer City",
          :publication_language => "es",
          :title => post.meta_tags.find_by(name: 'title').content,
          :keywords => post.meta_tags.find_by(name: 'keywords').content,
          :publication_date => post.updated_at,
          :genres => "Blog" }
  end

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
