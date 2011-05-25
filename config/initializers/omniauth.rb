require 'forcedotcom'
#
# Set the default hostname for omniauth to send callbacks to.
# seems to be a bug in omniauth that it drops the httpS
# this still exists in 0.2.0
#OmniAuth.config.full_host = "https://chouette-social.heroku.com/"
#OmniAuth.config.full_host = 'https://rhatter.heroku.com'

module OmniAuth
  module Strategies
    #tell omniauth to load our strategy
    autoload :Forcedotcom, 'lib/forcedotcom'
  end
end


Rails.application.config.middleware.use OmniAuth::Builder do
  # ALWAYS RESTART YOUR SERVER IF YOU MAKE CHANGES TO THESE SETTINGS!

  # you need a store for OpenID; (if you deploy on heroku you need Filesystem.new('./tmp') instead of Filesystem.new('/tmp'))
  require 'openid/store/filesystem'

  # providers with id/secret, you need to sign up for their services (see below) and enter the parameters here
  provider :facebook, ENV['fb_consumer_key'] , ENV['fb_consumer_secret'], :scope => 'email,offline_access, publish_stream, read_stream'
  provider :twitter, ENV['twitter_consumer_key'], ENV['twitter_consumer_secret']
  provider :linked_in, ENV['linkedin_consumer_key'], ENV['linkedin_consumer_secret']
  #provider :salesforce, ENV['salesforce_consumer_key'], ENV['salesforce_consumer_secret']
  #Overloading the adapter, because Omniauth sets to the login and not the prelogin
  provider :forcedotcom, ENV['salesforce_consumer_key'], ENV['salesforce_consumer_secret']

  # Sign-up urls for Facebook, Twitter, and Github
  # https://developers.facebook.com/setup
  # https://github.com/account/applications/new
  # https://developer.twitter.com/apps/new
end