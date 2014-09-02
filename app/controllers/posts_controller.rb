class PostsController < ApplicationController
  before_action :set_post, only: :show

  def index
    @feed_entries = Post.order published_at: :desc
  end

  def show
  end
  
  def set_post
    @post = Post.friendly.find(params[:id])
  end
end
