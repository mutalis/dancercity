class PagesController < ApplicationController
  def about
  end

  def privacy
  end

  def terms
  end

  def rasg
    admin_user = User.find_by uid: '100005971752949'

    if current_user == admin_user
      permissions = current_user.facebook.get_connections('me','permissions')
      @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
      @has_manage_pages_permission = permissions[0]['manage_pages'].to_i == 1 ? true : false

      unless @has_wallpost_permission && @has_manage_pages_permission
        @koala_oauth = Koala::Facebook::OAuth.new(ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'])
        @permissions_url = @koala_oauth.url_for_oauth_code(permissions: 'manage_pages,publish_stream', callback: root_url, display: 'page')
        redirect_to @permissions_url
      end
    else
      redirect_to root_path
    end
  end

end
