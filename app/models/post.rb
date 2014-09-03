class Post < ActiveRecord::Base
  extend FriendlyId

  belongs_to :user
  has_many :meta_tags
  
  # has_one :description, -> { where name: 'description' }, class_name: "MetaTag"

  friendly_id :define_slug, use: [:slugged, :history]
  
  def define_slug
    if self.respond_to? :summary
      summary[0..64].strip
    else
      SecureRandom.uuid
    end
  end

  def self.add_from_feed(feed_url)
    feed = Feedjira::Feed.fetch_and_parse(feed_url)
    add_entries(feed.entries)
    feed
  end

  def self.add_from_feed_daemon(feed_url, delay_interval = 30.minutes)
    feed = add_from_feed(feed_url)
    loop do
      sleep delay_interval
      puts 'Reading Feed'
      feed = Feedjira::Feed.update(feed)
      add_entries(feed.new_entries) if feed.updated?
    end
  end

  def seo_title
    meta_title = meta_tags.find_by(name: 'title')
    if meta_title.respond_to? :content
      meta_title.content
    else
      ''
    end
  end

  def seo_description
    meta_description = meta_tags.find_by(name: 'description')
    if meta_description.respond_to? :content
      meta_description.content
    else
      ''
    end
  end

  def seo_keywords
    meta_keywords = meta_tags.find_by(name: 'keywords')
    if meta_keywords.respond_to? :content
      meta_keywords.content
    else
      ''
    end
  end

  private
  def self.add_entries(entries)
    entries.each do |entry|
      unless exists? entry_id: entry.entry_id
        post = new(
          entry_id: entry.entry_id,
          title: entry.title,
          url: entry.url,
          summary: entry.summary,
          published_at: entry.published,
          user: User.first
        )

        MetaTag.create!(name: 'title', content: entry.title[0..69].strip, post: post)
        MetaTag.create!(name: 'description', content: entry.summary[0..159].strip, post: post)
        MetaTag.create!(name: 'keywords', content: 'tango, mexico, tango mexico, clases tango, clases de tango, milonga, milongas, musica de tango, musica tango, bailar tango', post: post)
      end
    end
  end

end
