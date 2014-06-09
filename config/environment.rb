# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Dancercity::Application.initialize!

# SMTP server configuration
ActionMailer::Base.smtp_settings = {
  :address => ENV!['EMAIL_SERVER'],
  :port => 25,
  :domain => ENV!['DOMAIN'],
  :user_name  => 'dancercity_manager@dancercity.net',
  :password  => ENV!['SMTP_PASS'],
  :authentication => :plain,
  :enable_starttls_auto => true
}
