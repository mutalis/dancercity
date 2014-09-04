class PostsController < ApplicationController
  before_action :set_post, only: :show

  def index
    set_meta_tags :title => 'Tango M&eacute;xico',
                  :description => 'Tango en M&eacute;xico. Espacio de participaci&oacute;n comunitaria donde puedes publicar sobre todo lo relacionado con el Tango.',
                  :keywords => 'tango, mexico, tango mexico, milonga, milongas, bailar tango, clases de tango, clases tango, maestros de tango, maestras de tango, maestro de tango, maestra de tango, musica de tango, musica tango, maestros de baile, programa de radio tango, bailar, baile, danza'

    @feed_entries = Post.order published_at: :desc
  end

  def show
    set_meta_tags title: @post.seo_title,
                  description: @post.seo_description,
                  keywords: @post.seo_keywords
  end

  private
  def set_post
    @post = Post.friendly.find(params[:id])
  end
end
