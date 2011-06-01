require 'omniauth/strategies/oauth2'

# Omniauth strategy for using oauth2 and force.com
# Author: qwall@salesforce.com
#
module OmniAuth
  module Strategies
    class Forcedotcom <  OmniAuth::Strategies::OAuth2

      def initialize(app, consumer_key = nil, consumer_secret = nil, options = {}, &block)
        client_options = {
          :site => 'https://login.salesforce.com',
          :authorize_path => '/services/oauth2/authorize',
          :access_token_path => '/services/oauth2/token'
        }

        # 'code' locks you into one site; 'token' works across sites.
        options.merge!(:response_type => 'token', :grant_type => 'authorization_code')

        super(app, :forcedotcom, consumer_key, consumer_secret, client_options, options, &block)
      end

      def auth_hash
        data = user_data
        OmniAuth::Utils.deep_merge(super, {
            'uid' => @access_token['id'],
            'credentials' => {
              "instance_url" => @access_token['instance_url'],
              "refresh_token" => @access_token.refresh_token,
              "consumer_key" => @access_token.client.id,
              "consumer_secret" => @access_token.client.secret

            },
            'extra' => {'user_hash' => data},
            'user_info' => {
              'email' => data['email'],
              'name' => data['display_name']
            }
          })
      end


      def user_data
        @data ||= MultiJson.decode(@access_token.get(@access_token['id']))
      rescue ::OAuth2::HTTPError => e
        if e.response.status == 302
          @data ||= MultiJson.decode(@access_token.get(e.response.headers['location']))
        else
          raise e
        end
      end
    end

  end
end