module ApplicationHelper
  def self.twitter_client(token, token_secret)
    Twitter.configure do |config|
      config.consumer_key = ENV['twitter_consumer_key']
      config.consumer_secret = ENV['twitter_consumer_secret']
      config.oauth_token = token
      config.oauth_token_secret = token_secret
    end
    return Twitter::Client.new
  end

  def self.fb_client(token)
    #token_secret is not used.
    return FbGraph::User.me(token)
  end

  def self.linkedin_client(token, token_secret)
    linkedin_client ||= LinkedIn::Client.new(ENV['linkedin_consumer_key'], ENV['linkedin_consumer_secret'])
    linkedin_client.authorize_from_access(token, token_secret)
    return linkedin_client
  end

  def self.chatter_client(refresh_token, sf_consumer_key, sf_consumer_secret)
    payload = 'grant_type=refresh_token' + '&client_id=' + sf_consumer_key + '&client_secret=' + sf_consumer_secret + '&refresh_token=' + refresh_token
    result = HTTParty.post('https://login.salesforce.com/services/oauth2/token',
      :body => payload)
    return result
  end

  def parse_twitter(message)
    q_message = message.gsub(/#\S\S\S+/) {|s| "<a href='http://twitter.com/#!/search?q=" + CGI::escape(s) + "'>" + s + "</a>"}
    at_message = q_message.gsub(/@\S\S\S+/) {|s| "<a href='http://twitter.com/#!/" + CGI::escape(s) + "'>" + s + "</a>"}
    return at_message
  end
end