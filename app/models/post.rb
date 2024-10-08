# encoding: UTF-8
require 'open-uri'

class Post < ActiveRecord::Base

  extend FriendlyId

  belongs_to :user
  has_many :meta_tags
  
  # has_one :description, -> { where name: 'description' }, class_name: "MetaTag"
  default_scope { order(created_at: :desc) }

  scope :published, -> { where('is_published = ?', true) }

  scope :no_hidden, -> { where.not(is_published: nil) }

  friendly_id :define_slug, use: [:slugged, :history]

  def is_published?
    is_published
  end

  def define_slug
    if link_name.present?
      link_name[0..64].strip
    elsif message.present?
      message[0..64].strip
    else
      SecureRandom.uuid
    end
  end

  def self.add_from_feed(fb_page_id)
    admin_user = User.find_by uid: '100005971752949'

    if admin_user
      # fb_page_id = 111998825520170

      # permissions = admin_user.facebook.get_connections('me','permissions')
      # @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
      # @has_manage_pages_permission = permissions[0]['manage_pages'].to_i == 1 ? true : false
      # 
      # if @has_wallpost_permission && @has_manage_pages_permission
      #   page_token = admin_user.facebook.get_page_access_token(fb_page_id)
      #   page_graph = Koala::Facebook::API.new(page_token)

        # page_feed = page_graph.get_connection('me', 'feed')
        page_feed = admin_user.facebook.get_connections(fb_page_id,'feed')
        add_entries(page_feed)
      # end
    end
  end

  def self.add_from_user_feed(user_id)
    user = User.find_by uid: user_id

    if user
      user_feed = user.facebook.get_connections('me','feed')
      add_entries(user_feed)
    end
  end

  def self.add_from_feed_daemon(feed_url, delay_interval = 30.minutes)
    feed = add_from_feed(feed_url)
    loop do
      sleep delay_interval
      puts 'Reading Feed'
      Feedjira::Feed.update(feed)

      if feed.updated?
        if feed.new_entries.size <= 100
          add_entries(feed.new_entries) 
        else
          feed = add_from_feed(feed_url)
        end
      end

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

  def put_in_fb_wall(post_url_value)

    admin_user = User.find_by uid: '100005971752949'

    if admin_user
      fb_page_id = 535306009870436
      
      permissions = admin_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
      @has_manage_pages_permission = permissions[0]['manage_pages'].to_i == 1 ? true : false

      if @has_wallpost_permission && @has_manage_pages_permission
        page_token = admin_user.facebook.get_page_access_token(fb_page_id)
        page_graph = Koala::Facebook::API.new(page_token)

        # link_text = " Puedes ver esta publicación en: #{post_url(self)}"
        # message = self.convert_to_text + link_text

        desc_text = get_posting_text
        page_graph.put_connections(fb_page_id,'feed', link: post_url_value, picture: self.picture_url, description: desc_text)
      end
    end
  end

  def tweet(post_url_value)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV!['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV!['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV!['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV!['TWITTER_ACCESS_SECRET']
    end

    status_text = post_url_value + " #tango\n" + get_posting_text

    # if the Post don't have a picture tweet only the text.
    if self.picture_url == nil
      client.update(status_text[0..136].strip + '...')
    else
      File.open('/tmp/tweet_image_file', 'wb') do |fo|
        fo.write open(self.picture_url).read
      end
      client.update_with_media(status_text[0..136].strip + '...', File.new('/tmp/tweet_image_file'))
    end
  end

  # Create the message to post
  def get_posting_text()
    if self.description.present?
      desc_text = self.description
    elsif self.message.present?
      desc_text = self.message
    elsif self.caption.present?
      desc_text = self.caption
    else
      desc_text = ''
    end
  end

  private
  def self.add_entries(entries)
    @graph_x = Koala::Facebook::API.new
    entries.each do |entry|
      if entry['status_type'] != 'approved_friend'
        unless exists? entry_id: entry['id']

          small_picture_url = entry['picture'] if entry['picture'].present?

          if entry['type'] == 'photo'
            fb_image_object = @graph_x.get_object(entry['object_id'])
            picture_url = fb_image_object['source']
            # get medium_picture_url
            # medium_picture_index = fb_image_object['images'].size - 4
            # medium_picture_url = fb_image_object['images'][medium_picture_index]['source']
          elsif (entry['type'] == 'video') && (entry['object_id'].present?)
            video_url = "https://www.facebook.com/video/embed?video_id=#{entry['object_id']}"
            picture_url = small_picture_url
            # medium_picture_url = small_picture_url
          elsif (entry['type'] == 'video') && (entry['link'].present?)
            video_url = entry['source']
            picture_url = small_picture_url
            # medium_picture_url = small_picture_url
          else
            video_url = nil
            picture_url = small_picture_url
            # medium_picture_url = small_picture_url
          end

          post = new.tap do |new_post|
            new_post.entry_id = entry['id']
            new_post.caption = entry['caption']
            new_post.published_at = entry['created_time'].to_time
            new_post.description = entry['description']
            new_post.link = entry['link']
            new_post.message = entry['message']
            new_post.link_name = entry['name']
            new_post.fb_object_id = entry['object_id']
            new_post.small_picture_url = small_picture_url
            new_post.video_url = video_url
            new_post.status_type_desc = entry['status_type']
            new_post.status_type = entry['type']

            new_post.picture_url = picture_url
            new_post.medium_picture_url = picture_url
            new_post.fb_permalink = "https://www.facebook.com/#{entry['id'].split('_')[0]}/posts/#{entry['id'].split('_')[1]}"
            new_post.user = User.first
          end

          if entry['description'].present?
            meta_text = entry['description']
          elsif entry['message'].present?
            meta_text = entry['message']
          elsif entry['caption'].present?
            meta_text = entry['caption']
          else
            meta_text = ''
          end

          # Don't save a empty Post. The Post most have at least one image or a text.
          if (small_picture_url.present?) || (meta_text.present?)
            MetaTag.create!(name: 'title', content: meta_text[0..69].strip, post: post)
            MetaTag.create!(name: 'description', content: meta_text[0..159].strip, post: post)
            MetaTag.create!(name: 'keywords', content: 'tango, mexico, tango mexico, milongas mexico, clases tango, clases de tango, milonga, milongas, musica de tango, musica tango, bailar tango', post: post)
          end

        end
      end # Only process entries that are not 'approved_friend'
    end
  end

end
