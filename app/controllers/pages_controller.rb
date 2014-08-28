class PagesController < ApplicationController
  def about
  end

  def privacy
  end

  def terms
  end
  
  def tangomexico
    if current_user
      permissions = current_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
      @has_manage_pages_permission = permissions[0]['manage_pages'].to_i == 1 ? true : false

      if @has_wallpost_permission && @has_manage_pages_permission
        page_token = User.first.facebook.get_page_access_token(535306009870436)
        page_graph = Koala::Facebook::API.new(page_token)
        page_info = page_graph.get_object('me')
        @page_feed = page_graph.get_connection('me', 'feed')
      else
        session[:fb_post] = params[:fb_post]
        @koala_oauth = Koala::Facebook::OAuth.new(ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'])
        @permissions_url = @koala_oauth.url_for_oauth_code(permissions: 'manage_pages,publish_stream', callback: tangomexico_url, display: 'page')
        redirect_to @permissions_url
      end
    else
      session[:fb_post] = nil
      redirect_to root_path
    end
    
  end

end
