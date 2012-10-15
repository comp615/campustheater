# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Ydc::Application.initialize!

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => "https://secure.its.yale.edu/cas/",
  :username_session_key => :cas_user,
  :extra_attributes_session_key => :cas_extra_attributes
)

ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => EMAIL_DOMAIN,
  :authentication => :plain,
  :user_name => EMAIL_USERNAME,
  :password => EMAIL_PASSWORD,
  :enable_starttls_auto => true  }