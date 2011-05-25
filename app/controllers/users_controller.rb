require "twitter"
require 'linkedin'
require 'oauth'
require 'yaml'
require 'json'
require 'fb_graph'
require 'asf-rest-adapter'
require 'nokogiri'
require 'xmlsimple'

require Rails.root.to_s + '/app/helpers/application_helper.rb'

class UsersController < ApplicationController
  def index
    if !current_user
      puts 'you are NOT logged in'
    else
      puts 'you are signed in.'
      @my_services = current_user.services.find(:all)

      get_my_feeds
    end
  end

  def get_my_feeds
    chatter = current_user.services.find(:first, :conditions => { :provider => 'forcedotcom' })
    #salesforce = current_user.services.find(:first, :conditions => { :provider => 'salesforce' })
    facebook = current_user.services.find(:first, :conditions => { :provider => 'facebook' })
    lnk = current_user.services.find(:first, :conditions => { :provider => 'linked_in' })
    twitter = current_user.services.find(:first, :conditions => { :provider => 'twitter' })

    if twitter
      begin
        do_twitter_feeds
      rescue Exception => e
        unless flash[:error].nil?
          flash[:error] << "You Twitter services has a problem: #{e.message}. Consider remove & add this service again"
        else
          flash[:error] = "You Twitter services has a problem: #{e.message}. Consider remove & add this service again"
        end
      end
    end
    if lnk
      begin
        do_linked_in_feeds
      rescue Exception => e
        unless flash[:error].nil?
          flash[:error] << "You LinkedIn services has a problem: #{e.message}. Consider remove & add this service again"
        else
          flash[:error] = "You LinkedIn services has a problem: #{e.message}. Consider remove & add this service again"
        end
      end

    end
    if chatter
      begin
        do_chatter_feeds
      rescue Exception => e
        unless flash[:error].nil?
          flash[:error] << "You Chatter services has a problem: #{e.message}. Consider remove & add this service again"
        else
          flash[:error] = "You Chatter services has a problem: #{e.message}. Consider remove & add this service again"
        end
      end

    end
    if facebook
      begin
        do_fb_feeds
      rescue Exception => e
        unless flash[:error].nil?
          flash[:error] << "You Facebook services has a problem: #{e.message}. Consider remove & add this service again"
        else
          flash[:error] = "You Facebook services has a problem: #{e.message}. Consider remove & add this service again"
        end
      end

    end

  end

  def do_chatter_feeds
    auth = current_user.services.find(:first, :conditions => { :provider => 'forcedotcom' })
    #using refresh_token to generate a new access_token
    token_refresh = auth.token_refresh
    sf_consumer_key = auth.sf_consumer_key
    sf_consumer_secret = auth.sf_consumer_secret
    ct = ApplicationHelper::chatter_client(token_refresh, sf_consumer_key, sf_consumer_secret)

    @rest_svr = ct['instance_url']
    access_token = ct['access_token']
    # Because ct['id'] is in https://login.salesforce.com/id/Org_ID/User_ID format, trim it
    # https://login.salesforce.com/id/00DA0000000XpCkMAK/00ENV['default_feed_counts'].to_sA0000000S2C7IAK
    profile_id = ct['id'].gsub(/\S+\//mi, "")
    api_version=ENV['salesforce_rest_api'] # 'v21.0'
    header = { "Authorization" => "OAuth " + access_token, "content-Type" => 'application/json' }

    #ct_user = Salesforce::Rest::User.find(profile_id)

    query = "SELECT Id, CreatedDate, CreatedBy.Name, CreatedBy.Id, FeedPost.Id, FeedPost.Body from UserFeed where parentid='#{profile_id}' order by CreatedDate Desc limit #{ENV['default_feed_counts'].to_s}"
    @chatter_feeds = Salesforce::Rest::AsfRest.run_soql(query, header, @rest_svr, api_version)['records']

  end

  def do_twitter_feeds
    # My Twitter Feed
    auth = current_user.services.find(:first, :conditions => { :provider => 'twitter' })
    token = auth.token
    token_secret = auth.token_secret
    tc = ApplicationHelper::twitter_client(token, token_secret)

    # See doc http://rubydoc.info/gems/twitter/1.2.0/Twitter/Client/Timeline
    @twitter_feeds = tc.home_timeline({:count => ENV['default_feed_counts'].to_s})
  end
  
  def do_linked_in_feeds
    #linked In feeds
    auth = current_user.services.find(:first, :conditions => { :provider => 'linked_in' })
    token = auth.token
    token_secret = auth.token_secret
    lnk_client = ApplicationHelper::linkedin_client(token, token_secret)
    linked_in_profile = lnk_client.profile(:fields => ['first-name', 'last-name', 'headline', 'current-share'])
    network_feeds = lnk_client.network_updates({:count => ENV['default_feed_counts'].to_s, :scope => 'self'})
    #now parsing a Nokiri document
    @linked_in_feeds = XmlSimple.xml_in(network_feeds.instance_variable_get("@doc").to_s)['updates'][0]['update']    
  end

  def do_fb_feeds
    auth = current_user.services.find(:first, :conditions => { :provider => 'facebook' })
    token = auth.token
    token_secret = auth.token_secret
    fb = ApplicationHelper::fb_client(token)
    #a_user = FbGraph::User.fetch('id_please')
    @fb_feeds = fb.feed({:limit => ENV['default_feed_counts'].to_s})
  end

  def setwallpaper
    #current_user.update(:wallpaper => params[:wallpaper])
    current_user.update_attributes(:wallpaper => params[:wallpaper].to_s)
    flash[:notice] = "You wallpaper has been updated to use #{current_user.wallpaper}"
    redirect_to services_path
    return
  end

end
