OmniAuth.config.logger = Rails.logger

cert_path = `openssl version -a`.match(%r~.*OPENSSLDIR: ("[a-zA-Z\/]+")~)[1]
cert_path.gsub! /"/,''

ca_file = cert_path + '/cert.pem'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV!['FACEBOOK_KEY'], ENV!['FACEBOOK_SECRET'],
            scope: 'basic_info, email, user_location', :display => 'page',
            :client_options => {
              :ssl => {:ca_file => ca_file}
             }
end
