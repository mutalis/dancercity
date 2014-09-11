# encoding: UTF-8

class Post < ActiveRecord::Base
  extend FriendlyId

  belongs_to :user
  has_many :meta_tags
  
  # has_one :description, -> { where name: 'description' }, class_name: "MetaTag"
  default_scope { order(created_at: :desc) }

  scope :published, -> { where('is_published = ?', true) }

  friendly_id :define_slug, use: [:slugged, :history]

  def is_published?
    is_published
  end

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

  def add_comment_in_fb
    admin_user = User.find_by uid: '100005971752949'

    if admin_user
      fb_page_id = 535306009870436
      fb_comment_id = admin_user.facebook.get_object('', id: URI::escape(self.url))['id']
      
      permissions = admin_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
      @has_manage_pages_permission = permissions[0]['manage_pages'].to_i == 1 ? true : false

      if @has_wallpost_permission && @has_manage_pages_permission
        page_token = admin_user.facebook.get_page_access_token(fb_page_id)
        page_graph = Koala::Facebook::API.new(page_token)
        comment = "Puedes ver esta publicación en:\n #{post_url(self)}"

        page_graph.put_connections("#{fb_page_id}_#{fb_comment_id}",'comments', message: comment)
      end
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
        
        post.add_comment_in_fb
      end
    end
  end

end
