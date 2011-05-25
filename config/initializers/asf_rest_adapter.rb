#require 'forcedotcom' # no longer needed, it is a part of the asf-rest-adapter
require 'asf-rest-adapter'

# Set the default hostname for omniauth to send callbacks to.
# seems to be a bug in omniauth that it drops the httpS
# this still exists in 0.2.0
#OmniAuth.config.full_host = 'https://localhost:3000'

module OmniAuth
  module Strategies
    #tell Omniauth to load our strategy
    autoload :Forcedotcom, 'lib/forcedotcom'
  end
end

config_file = Rails.root.to_s + "/config/asf_rest_config.yml"
Salesforce::Rest::AsfRest.ignite_adapter(config_file)