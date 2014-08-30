class Post < ActiveRecord::Base
  extend FriendlyId

  belongs_to :user

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
  end

  def self.update_from_feed(feed_url)
    feed = Feedjira::Feed.fetch_and_parse(feed_url)
    feed = Feedjira::Feed.update(feed)
    add_entries(feed.new_entries) if feed.updated?
  end

  private
  def self.add_entries(entries)
    entries.each do |entry|
      unless exists? entry_id: entry.entry_id
        create!(
          entry_id: entry.entry_id,
          title: entry.title,
          url: entry.url,
          summary: entry.summary,
          published_at: entry.published,
          user: User.first
        )
      end
    end
  end

end
