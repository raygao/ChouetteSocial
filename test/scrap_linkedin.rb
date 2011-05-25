=begin
      ENV['linkedin_consumer_key'] = 's13__WR4HkwEcRu6K6j0ZfsVZkgYWsjUXpoek-dnp_vSoGLpmIUX08YG-xUplFDG'
      ENV['linkedin_consumer_secret'] = 'rADqcn8YkZHR_7m9sgQNb-XRTerC4GrCCysBLW9jyyLqIGM98RhWfMFLh6NoT4Lz'
      config = YAML.load(<<EOS
linkedin-example:
  api_host: https://api.linkedin.com
  request_token_path: /uas/oauth/requestToken
  access_token_path: /uas/oauth/accessToken
  authorize_path: /uas/oauth/authorize
  consumer_key: 's13__WR4HkwEcRu6K6j0ZfsVZkgYWsjUXpoek-dnp_vSoGLpmIUX08YG-xUplFDG'
  consumer_secret: 'rADqcn8YkZHR_7m9sgQNb-XRTerC4GrCCysBLW9jyyLqIGM98RhWfMFLh6NoT4Lz'
EOS
      )

      oauth_options = config['linkedin-example']

      consumer_options = { :site => oauth_options['api_host'],
        :authorize_path => oauth_options['authorize_path'],
        :request_token_path => oauth_options['request_token_path'],
        :access_token_path => oauth_options['access_token_path'] }

      consumer = OAuth::Consumer.new(ENV['linkedin_consumer_key'], ENV['linkedin_consumer_secret'], consumer_options)
      access_token = OAuth::AccessToken.new(consumer, session['linkedin_access_token'], session['linkedin_access_secret'])

      # Pick some fields
      fields = ['first-name', 'last-name', 'headline', 'industry', 'num-connections'].join(',')

      # Make a request for JSON data
      json_txt = access_token.get("/v1/people/~:(#{fields})", 'x-li-format' => 'json').body
      profile = JSON.parse(json_txt)
      puts "Profile data:"
      puts JSON.pretty_generate(profile)
      render :text => JSON.pretty_generate(profile)
=end