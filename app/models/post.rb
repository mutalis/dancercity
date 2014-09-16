# encoding: UTF-8
require 'htmlentities'

class Post < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  extend FriendlyId

  belongs_to :user
  has_many :meta_tags
  
  # has_one :description, -> { where name: 'description' }, class_name: "MetaTag"
  default_scope { order(created_at: :asc) }

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

  def put_in_fb_wall
    default_url_options[:host] = 'http://www.dancercity.net'

    admin_user = User.find_by uid: '100005971752949'

    if admin_user
      fb_page_id = 535306009870436
      
      permissions = admin_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
      @has_manage_pages_permission = permissions[0]['manage_pages'].to_i == 1 ? true : false

      if @has_wallpost_permission && @has_manage_pages_permission
        page_token = admin_user.facebook.get_page_access_token(fb_page_id)
        page_graph = Koala::Facebook::API.new(page_token)

        link_text = " Puedes ver esta publicación en: #{post_url(self)}"
        message = self.convert_to_text + link_text

        page_graph.put_connections(fb_page_id,'feed', message: message)
      end
    end
  end

  # Returns the text in UTF-8 format with all HTML tags removed
  #
  # TODO: add support for DL, OL
  def convert_to_text(line_length = 65, from_charset = 'UTF-8')
    txt = summary

    # replace images with their alt attributes
    # for img tags with "" for attribute quotes
    # with or without closing tag
    # eg. the following formats:
    # <img alt="" />
    # <img alt="">
    txt.gsub!(/<img.+?alt=\"([^\"]*)\"[^>]*\>/i, '\1')

    # for img tags with '' for attribute quotes
    # with or without closing tag
    # eg. the following formats:
    # <img alt='' />
    # <img alt=''>
    txt.gsub!(/<img.+?alt=\'([^\']*)\'[^>]*\>/i, '\1')

    # links
    # txt.gsub!(/<a.+?href=\"(mailto:)?([^\"]*)\"[^>]*>((.|\s)*?)<\/a>/i) do |s|
    txt.gsub!(/<a\s.*href=\"(mailto:)?([^\"]*)\"[^>]*>((.|\s)*?)<\/a>/i) do |s|
      if $3.empty?
        ''
      else
        $3.strip + ' ( ' + $2.strip + ' )'
      end
    end

    # txt.gsub!(/<a.+?href='(mailto:)?([^\']*)\'[^>]*>((.|\s)*?)<\/a>/i) do |s|
    txt.gsub!(/<a\s.*?href='(mailto:)?([^\']*)\'[^>]*>((.|\s)*?)<\/a>/i) do |s|
      if $3.empty?
        ''
      else
        $3.strip + ' ( ' + $2.strip + ' )'
      end
    end

    # handle headings (H1-H6)
    txt.gsub!(/(<\/h[1-6]>)/i, "\n\\1") # move closing tags to new lines
    txt.gsub!(/[\s]*<h([1-6]+)[^>]*>[\s]*(.*)[\s]*<\/h[1-6]+>/i) do |s|
      hlevel = $1.to_i

      htext = $2
      htext.gsub!(/<br[\s]*\/?>/i, "\n") # handle <br>s
      htext.gsub!(/<\/?[^>]*>/i, '') # strip tags

      # determine maximum line length
      hlength = 0
      htext.each_line { |l| llength = l.strip.length; hlength = llength if llength > hlength }
      hlength = line_length if hlength > line_length

      case hlevel
        when 1   # H1, asterisks above and below
          htext = ('*' * hlength) + "\n" + htext + "\n" + ('*' * hlength)
        when 2   # H1, dashes above and below
          htext = ('-' * hlength) + "\n" + htext + "\n" + ('-' * hlength)
        else     # H3-H6, dashes below
          htext = htext + "\n" + ('-' * hlength)
      end

      "\n\n" + htext + "\n\n"
    end

    # wrap spans
    txt.gsub!(/(<\/span>)[\s]+(<span)/mi, '\1 \2')

    # lists -- TODO: should handle ordered lists
    txt.gsub!(/[\s]*(<li[^>]*>)[\s]*/i, '* ')
    # list not followed by a newline
    txt.gsub!(/<\/li>[\s]*(?![\n])/i, "\n")

    # paragraphs and line breaks
    txt.gsub!(/<\/p>/i, "\n\n")
    txt.gsub!(/<br[\/ ]*>/i, "\n")

    # strip remaining tags
    txt.gsub!(/<\/?[^>]*>/, '')

    # decode HTML entities
    he = HTMLEntities.new
    txt = he.decode(txt)

    txt = word_wrap(txt, line_length)

    # remove linefeeds (\r\n and \r -> \n)
    txt.gsub!(/\r\n?/, "\n")

    # strip extra spaces
    txt.gsub!(/\302\240+/, " ") # non-breaking spaces -> spaces
    txt.gsub!(/\n[ \t]+/, "\n") # space at start of lines
    txt.gsub!(/[ \t]+\n/, "\n") # space at end of lines

    # no more than two consecutive newlines
    txt.gsub!(/[\n]{3,}/, "\n\n")

    # no more than two consecutive spaces
    txt.gsub!(/ {2,}/, " ")

    # the word messes up the parens
    txt.gsub!(/\([ \n](http[^)]+)[\n ]\)/) do |s|
      "( " + $1 + " )"
    end

    txt.strip
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
        
        post.put_in_fb_wall
      end
    end
  end

  # Taken from Rails' word_wrap helper (http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-word_wrap)
  def word_wrap(txt, line_length)
    txt.split("\n").collect do |line|
      line.length > line_length ? line.gsub(/(.{1,#{line_length}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end
