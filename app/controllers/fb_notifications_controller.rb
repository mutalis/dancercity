class FbNotificationsController < ApplicationController
  def send_message
    if current_user
      permissions = current_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false

      if @has_wallpost_permission
        # current_user.invite_friends
        logger.info 'SEND IT'
        current_user.facebook.put_connections("me", "feed", :message => "Meet people that enjoy of the ballroom dancing and make new friends using your Facebook account. Sign in at: http://www.dancercity.net")
        redirect_to root_path
      else
        @koala_oauth = Koala::Facebook::OAuth.new(ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'])
        @permissions_url = @koala_oauth.url_for_oauth_code(permissions: 'publish_stream', callback: fb_notifications_send_url, display: 'page')
        redirect_to @permissions_url
      end

    else
      redirect_to root_path
    end
  end
end
