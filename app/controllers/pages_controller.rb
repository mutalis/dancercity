class PagesController < ApplicationController
  def about
  end

  def privacy
  end

  def terms
  end
  
  def tangomexico
    if current_user
      @feed_entries = Post.all
    else
      redirect_to root_path
    end
    
  end

end
