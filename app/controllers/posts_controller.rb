class PostsController < ApplicationController
  before_action :set_post, only: [:show, :update]

  def index
    set_meta_tags :title => 'Tango M&eacute;xico',
                  :description => 'Tango en M&eacute;xico. Espacio de participaci&oacute;n comunitaria donde puedes publicar sobre todo lo relacionado con el Tango.',
                  :keywords => 'tango, mexico, tango mexico, milonga, milongas, bailar tango, clases de tango, clases tango, maestros de tango, maestras de tango, maestro de tango, maestra de tango, musica de tango, musica tango, maestros de baile, programa de radio tango, bailar, baile, danza'

    @feed_entries = Post.published
    @feed_entries = Post.all if current_user && current_user.admin?
  end

  def show
    set_meta_tags title: @post.seo_title,
                  description: @post.seo_description,
                  keywords: @post.seo_keywords
  end

  def update
    if params[:is_published] == 'true'
      flash.now[:notice] = "You've accepted the Post." if @post.update(is_published: params[:is_published])
      @post.put_in_fb_wall
    elsif params[:is_published] == 'false'
      flash.now[:notice] = "You've deleted the Post." if @post.destroy
      @deleted = true
    end
  end

  private
  def set_post
    @post = Post.friendly.find(params[:id])
  end

end
