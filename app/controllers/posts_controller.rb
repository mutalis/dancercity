# encoding: UTF-8

require 'will_paginate/array'

class PostsController < ApplicationController
  before_action :set_post, only: [:show, :update]

  def index
    set_meta_tags :title => 'Tango México',
                  :description => 'Tango en México. Espacio de participación comunitaria donde puedes publicar sobre todo lo relacionado con el Tango.',
                  :keywords => 'tango, mexico, tango mexico, milonga, milongas, bailar tango, clases de tango, clases tango, maestros de tango, maestras de tango, maestro de tango, maestra de tango, musica de tango, musica tango, maestros de baile, programa de radio tango, bailar, baile, danza'

    @feed_entries = Post.published
    @feed_entries = Post.no_hidden if current_user && current_user.admin?
    # paginate the posts
    @feed_entries = @feed_entries.paginate(:page => params[:page], :per_page => 10)
  end

  def show
    post_url_value = post_url(@post)

    set_meta_tags title: @post.seo_title,
                  description: @post.seo_description,
                  keywords: @post.seo_keywords,
                  fb: {app_id: ENV!['FACEBOOK_KEY']},
                  og: {title: @post.seo_title, type: 'website', url: post_url_value, locale: 'es_ES',
                       description: @post.seo_description, site_name: 'Dancer City',
                       image: CGI::unescapeHTML(@post.medium_picture_url}),
                  twitter: {card: 'summary_large_image', title: @post.seo_title,
                            description: @post.seo_description, image: CGI::unescapeHTML(@post.picture_url)}

  end

  def update
    if params[:is_published] == 'true'
      flash.now[:notice] = "You've accepted the Post." if @post.update(is_published: params[:is_published])
      @post.put_in_fb_wall(post_url(@post))
    elsif params[:is_published] == 'false'
      flash.now[:notice] = "You've hidden the Post." if @post.update(is_published: nil)
      @deleted = true
    end
  end

  private
  def set_post
    @post = Post.friendly.find(params[:id])
  end

end
