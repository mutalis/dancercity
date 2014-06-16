class FbNotificationsController < ApplicationController
  def send_message
    if current_user.friends_invitations_sent?
      redirect_to root_path
    else
      permissions = current_user.facebook.get_connections('me','permissions')
      @has_chat_permission = permissions[0]['xmpp_login'].to_i == 1 ? true : false

      if @has_chat_permission
        current_user.invite_friends
        redirect_to root_path
      else
        @koala_oauth = Koala::Facebook::OAuth.new(ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'])
        @permissions_url = @koala_oauth.url_for_oauth_code(permissions: 'xmpp_login', callback: fb_notifications_send_url, display: 'page')
        redirect_to @permissions_url
      end
    end
  end

  def post_to_wall
    if current_user && (params[:fb_post].present?)
      permissions = current_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false

      if @has_wallpost_permission
        current_user.facebook.put_connections("me", "feed", :message => params[:fb_post])
        session[:fb_post] = nil
        redirect_to root_path, notice: 'Your message was successfully posted to your Facebook wall.'
      else
        session[:fb_post] = params[:fb_post]
        @koala_oauth = Koala::Facebook::OAuth.new(ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'])
        @permissions_url = @koala_oauth.url_for_oauth_code(permissions: 'publish_stream', callback: root_url, display: 'page')
        redirect_to @permissions_url
      end
    else
      session[:fb_post] = nil
      redirect_to root_path
    end
  end

end
