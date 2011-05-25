require "twitter"
require 'linkedin'
require 'oauth'
require 'yaml'
require 'json'
require 'fb_graph'
require 'asf-rest-adapter'
require 'httparty'

require Rails.root.to_s + '/app/helpers/application_helper.rb'

class FeedpostsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  
  
  def add_new
    flash[:notice] = ""
    flash[:error]  = ""

    message = params[:feed_update]
    unless message.nil? || message.empty?
      if params[:chatter] || params[:forcedotcom]
        chatter = true
        begin
          auth = current_user.services.find(:first, :conditions => { :provider => 'forcedotcom' })
          #using refresh_token to generate a new access_token
          token_refresh = auth.token_refresh
          sf_consumer_key = auth.sf_consumer_key
          sf_consumer_secret = auth.sf_consumer_secret
          ct = ApplicationHelper::chatter_client(token_refresh, sf_consumer_key, sf_consumer_secret)
          
          rest_svr = ct['instance_url']
          access_token = ct['access_token']
          # Because ct['id'] is in https://login.salesforce.com/id/Org_ID/User_ID format, trim it
          # https://login.salesforce.com/id/00DA0000000XpCkMAK/005A0000000S2C7IAK
          profile_id = ct['id'].gsub(/\S+\//mi, "")
          api_version=ENV['salesforce_rest_api'] # 'v21.0'
          header = { "Authorization" => "OAuth " + access_token, "content-Type" => 'application/json' }

          serialized_json = '{"CurrentStatus":"' + message + '"}'
          resp = Salesforce::Rest::User.update(profile_id, serialized_json, header, rest_svr, api_version)
          # query = 'select Id, Name from Account'
          # results = Salesforce::Rest::AsfRest.run_soql(query, header, rest_svr, api_version)
          # puts '### results' + results.to_s
          if resp.code == '204'
            #Per REST api DOC, code 204 signify it was saved to User's CurrentStatus.
            logger.info(message + "was posted to Chatter on: " + DateTime.now().to_s)
            flash[:notice] << "Message has been sent to Chatter.   "
            puts '### results' + resp.to_s
          else
            raise Exception.new("Cannot post to Chatter, not getting respose code of 204.")
          end

        rescue Exception => e
          flash[:error] << "Cannot post to Chatter, due to #{e.message}."
          logger.error("*** Error occured in posting to Chatter, #{e.message}")
        end
      end

      if params[:facebook]
        facebook = true
        begin
          auth = current_user.services.find(:first, :conditions => { :provider => 'facebook' })
          token = auth.token
          token_secret = auth.token_secret
          fb = ApplicationHelper::fb_client(token)
          result = fb.feed!(
            :message => message,
            #:picture => 'https://graph.facebook.com/matake/picture',
            :link => 'http://raysblog.are4.us',
            :name => 'Chouette Social',
            :description => 'Update via Chouette Social application.'
          )
          logger.info(message + "was posted to Facebook on: " + DateTime.now().to_s)
          flash[:notice] << "Message has been sent to Facebook.   "
        rescue Exception => e
          flash[:error] << "Cannot post to Facebook, due to #{e.message}."
          logger.error("*** Error occured in posting to Facebook, #{e.message}")
        end
      end

      if params[:linked_in]
        linked_in = true
        begin
          auth = current_user.services.find(:first, :conditions => { :provider => 'linked_in' })
          token = auth.token
          token_secret = auth.token_secret
          lclient = ApplicationHelper::linkedin_client(token, token_secret)
          result = lclient.update_status(message)
          logger.info(message + "was posted to LinkedIn on: " + DateTime.now().to_s)
          flash[:notice] << "Message has been sent to LinkedIn.   "
        rescue Exception => e
          flash[:error] << "Cannot post to LinkedIn, due to #{e.message}."
          logger.error("*** Error occured in posting to LinkedIn, #{e.message}")
        end
      end

      if params[:twitter]
        twitter = true
        begin
          auth = current_user.services.find(:first, :conditions => { :provider => 'twitter' })
          token = auth.token
          token_secret = auth.token_secret
          tc = ApplicationHelper::twitter_client(token, token_secret)
          result = tc.update(message)
          logger.info(message + "was posted to Twitter on: " + DateTime.now().to_s)
          flash[:notice] << "Message has been sent to Twitter.   "
        rescue Exception => e
          flash[:error] << "Cannot post to Twitter, due to #{e.message}."
          logger.error("*** Error occured in posting to Twitter, #{e.message}")
        end
      end

      if flash[:notice].empty?
        flash.delete(:notice)
      end
      if flash[:error].empty?
        flash.delete(:error)
      end
      #now go back to the root url
      redirect_to root_url
      return

      #Should not allow posting a blank message. It is senseless.
    else
      flash[:error] = "Cannot send a blank message."
      redirect_to root_url
      return
    end
  end

   
end
