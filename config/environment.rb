# Load the rails application
require File.expand_path('../application', __FILE__)

# default, where RAILS_ENV == 'production'
if RAILS_ENV == 'production'
  ENV['twitter_consumer_key'] = 'Your Twitter CK'
  ENV['twitter_consumer_secret'] = 'Your Twitter CS'

  ENV['fb_consumer_key'] = 'Your Facebook CK'
  ENV['fb_consumer_secret'] = 'Your Facebook CS'

  ENV['linkedin_consumer_key'] = 'Your LinkedIn CK'
  ENV['linkedin_consumer_secret'] = 'Your LinkedIn CS'

  ENV['salesforce_consumer_key'] = 'Your Chatter/Salesforce CK'
  ENV['salesforce_consumer_secret'] = 'Your Chatter/Salesforce CS'
  ENV['salesforce_rest_api'] = 'v21.0'  # version 21 or above

  ## for the development environment
elsif RAILS_ENV == 'development'
  ENV['twitter_consumer_key'] = 'Your Twitter CK'
  ENV['twitter_consumer_secret'] = 'Your Twitter CS'

  ENV['fb_consumer_key'] = 'Your Facebook CK'
  ENV['fb_consumer_secret'] = 'Your Facebook CS'

  ENV['linkedin_consumer_key'] = 'Your LinkedIn CK'
  ENV['linkedin_consumer_secret'] = 'Your LinkedIn CS'

  ENV['salesforce_consumer_key'] = 'Your Chatter/Salesforce CK'
  ENV['salesforce_consumer_secret'] = 'Your Chatter/Salesforce CS'
  ENV['salesforce_rest_api'] = 'v21.0'  # version 21 or above

  #default back to production
else
  ENV['twitter_consumer_key'] = 'Your Twitter CK'
  ENV['twitter_consumer_secret'] = 'Your Twitter CS'

  ENV['fb_consumer_key'] = 'Your Facebook CK'
  ENV['fb_consumer_secret'] = 'Your Facebook CS'

  ENV['linkedin_consumer_key'] = 'Your LinkedIn CK'
  ENV['linkedin_consumer_secret'] = 'Your LinkedIn CS'

  ENV['salesforce_consumer_key'] = 'Your Chatter/Salesforce CK'
  ENV['salesforce_consumer_secret'] = 'Your Chatter/Salesforce CS'
  ENV['salesforce_rest_api'] = 'v21.0'  # version 21 or above

end

# Initialize the rails application
ChouetteSocial::Application.initialize!


