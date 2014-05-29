OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'],
            scope: 'basic_info, user_location, xmpp_login', :display => 'page'
end
