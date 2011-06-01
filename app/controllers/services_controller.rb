class ServicesController < ApplicationController
  before_filter :authenticate_user!, :except => [:create, :signin, :signup, :newaccount, :failure]
  
  protect_from_forgery :except => :create     # https://github.com/intridea/omniauth/issues/203


  # GET all authentication services assigned to the current user
  def index
    @services = current_user.services.order('provider asc')
  end

  # POST to remove an authentication service
  def destroy
    # remove an authentication service linked to the current user
    @service = current_user.services.find(params[:id])
    
    if session[:service_id] == @service.id
      flash[:error] = 'You are currently signed in with this account!'
    else
      @service.destroy
    end
    
    redirect_to services_path
  end

  # POST from signup view
  def newaccount
    if params[:commit] == "Cancel"
      session[:authhash] = nil
      session.delete :authhash
      redirect_to root_url
    else  # create account
      @newuser = User.new
      @newuser.name = session[:authhash][:name]
      @newuser.email = session[:authhash][:email]
      @newuser.services.build(
        :provider => session[:authhash][:provider],
        :uid => session[:authhash][:uid],
        :uname => session[:authhash][:name],
        :uemail => session[:authhash][:email],
        :token => session[:authhash][:token],
        :token_secret => session[:authhash][:token_secret],
        :token_refresh => session[:authhash][:token_refresh],
        :sf_consumer_key => session[:authhash][:sf_consumer_key],
        :sf_consumer_secret => session[:authhash][:sf_consumer_secret]
      )
      logger.info("---> New User created with service. #{session[:authhash][:provider]}")

      if @newuser.save!
        # signin existing user
        # in the session his user id and the service id used for signing in is stored
        session[:user_id] = @newuser.id
        session[:service_id] = @newuser.services.first.id
        
        flash[:notice] = 'Your account has been created and you have been signed in!'
        redirect_to root_url
      else
        flash[:error] = 'This is embarrassing! There was an error while creating your account from which we were not able to recover.'
        redirect_to root_url
      end  
    end
  end  
  
  # Sign out current user
  def signout 
    if current_user
      session[:user_id] = nil
      session[:service_id] = nil
      session.delete :user_id
      session.delete :service_id
      flash[:notice] = 'You have been signed out!'
    end  
    redirect_to root_url
  end
  
  # callback: success
  # This handles signing in and adding an authentication service to existing accounts itself
  # It renders a separate view if there is a new user to create
  def create
    # get the service parameter from the Rails router
    params[:service] ? service_route = params[:service] : service_route = 'No service recognized (invalid callback)'

    # get the full hash from omniauth
    omniauth = request.env['omniauth.auth']
    
    # continue only if hash and parameter exist
    if omniauth and params[:service]

      # map the returned hashes to our variables first - the hashes differs for every service
      
      # create a new hash
      @authhash = Hash.new
      
      if service_route == 'facebook'
        omniauth['extra']['user_hash']['email'] ? @authhash[:email] =  omniauth['extra']['user_hash']['email'] : @authhash[:email] = ''
        omniauth['extra']['user_hash']['name'] ? @authhash[:name] =  omniauth['extra']['user_hash']['name'] : @authhash[:name] = ''
        omniauth['extra']['user_hash']['id'] ?  @authhash[:uid] =  omniauth['extra']['user_hash']['id'].to_s : @authhash[:uid] = ''
        omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
        omniauth['credentials']['token'] ? @authhash[:token] = omniauth['credentials']['token'] : @authhash[:token] = ''

        omniauth['credentials']['token'] ? @authhash[:token] = omniauth['credentials']['token'] : @authhash[:token] = ''
        # Facebook do not use secret. It is perpetual based on offline_access
        @authhash[:token_secret] = ''
        # sf_cs, token_refresh, and sf_ck are only for chatter
        @authhash[:sf_consumer_key] = ''
        @authhash[:sf_consumer_secret] = ''
        @authhash[:token_refresh] = ''
        
      elsif service_route == 'linked_in'
        omniauth['user_info']['email'] ? @authhash[:email] =  omniauth['user_info']['email'] : @authhash[:email] = ''
        omniauth['user_info']['name'] ? @authhash[:name] =  omniauth['user_info']['name'] : @authhash[:name] = ''
        omniauth['uid'] ? @authhash[:uid] = omniauth['uid'].to_s : @authhash[:uid] = ''
        omniauth['provider'] ? @authhash[:provider] =  omniauth['provider'] : @authhash[:provider] = ''

        omniauth['credentials']['token'] ? @authhash[:token] = omniauth['credentials']['token'] : @authhash[:token] = ''
        omniauth['credentials']['secret'] ? @authhash[:token_secret] = omniauth['credentials']['secret'] : @authhash[:token_secret] = ''
        # sf_cs, token_refresh, and sf_ck are only for chatter
        @authhash[:sf_consumer_key] = ''
        @authhash[:sf_consumer_secret] = ''
        @authhash[:token_refresh] = ''

      elsif service_route == 'chatter' || service_route == 'forcedotcom'
        omniauth['user_info']['email'] ? @authhash[:email] =  omniauth['user_info']['email'] : @authhash[:email] = ''
        omniauth['user_info']['name'] ? @authhash[:name] =  omniauth['user_info']['name'] : @authhash[:name] = ''
        omniauth['extra']['user_hash']['user_id'] ? @authhash[:uid] =  omniauth['extra']['user_hash']['user_id'].to_s : @authhash[:uid] = ''
        omniauth['provider'] ? @authhash[:provider] =  omniauth['provider'] : @authhash[:provider] = ''
        # note Salesforce's refresh-token is not stored on the omniauth tree, it is instead at
        # request.env['omniauth.strategy'].instance_variable_get(:@access_token).instance_variable_get(:@refresh_token)
        # Furthermore, due to time-out, Force.com's token is session based and does not last forever.
        # You need to use refresh_token to regenerate the access_token
        # @authhash[:token_refresh] = request.env['omniauth.strategy'].instance_variable_get(:@access_token).instance_variable_get(:@refresh_token)
        # @authhash[:sf_consumer_key] = request.env['omniauth.strategy'].instance_variable_get(:@access_token).client.id
        # @authhash[:sf_consumer_secret] = request.env['omniauth.strategy'].instance_variable_get(:@access_token).client.secret

        @authhash[:token] = omniauth['credentials']['token']
        @authhash[:token_secret] = '' #Not used only for LinkedIn / Twitter
        @authhash[:token_refresh] = omniauth['credentials']['refresh_token']
        @authhash[:sf_consumer_key] = omniauth['credentials']['consumer_key']
        @authhash[:sf_consumer_secret] = omniauth['credentials']['consumer_secret']
      elsif service_route == 'twitter'
        omniauth['user_info']['email'] ? @authhash[:email] =  omniauth['user_info']['email'] : @authhash[:email] = ''
        omniauth['user_info']['name'] ? @authhash[:name] =  omniauth['user_info']['name'] : @authhash[:name] = ''
        omniauth['uid'] ? @authhash[:uid] = omniauth['uid'].to_s : @authhash[:uid] = ''
        omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''

        omniauth['credentials']['token'] ? @authhash[:token] = omniauth['credentials']['token'] : @authhash[:token] = ''
        omniauth['credentials']['secret'] ? @authhash[:token_secret] = omniauth['credentials']['secret'] : @authhash[:token_secret] = ''
        # sf_cs, token_refresh, and sf_ck are only for chatter
        @authhash[:sf_consumer_key] = ''
        @authhash[:sf_consumer_secret] = ''
        @authhash[:token_refresh] = ''

      else        
        # debug to output the hash that has been returned when adding new services
        render :text => omniauth.to_yaml
        return
      end 
      
      if @authhash[:uid] != '' and @authhash[:provider] != ''
        
        auth = Service.find_by_provider_and_uid(@authhash[:provider], @authhash[:uid])

        # if the user is currently signed in, he/she might want to add another account to signin
        if user_signed_in?
          if auth
            flash[:notice] = 'Your account at ' + @authhash[:provider].capitalize + ' is already connected with this site.'
            redirect_to services_path
          else
            current_user.services.create!(
              :provider => @authhash[:provider],
              :uid => @authhash[:uid],
              :uname => @authhash[:name],
              :uemail => @authhash[:email],
              :token => @authhash[:token],
              :token_secret => @authhash[:token_secret],
              :token_refresh => @authhash[:token_refresh],
              :sf_consumer_key => @authhash[:sf_consumer_key],
              :sf_consumer_secret => @authhash[:sf_consumer_secret]
            )
            flash[:notice] = 'Your ' + @authhash[:provider].capitalize + ' account has been added for signing in at this site.'
            logger.info("---> Current_user add a new service. #{@authhash[:provider]}")
            redirect_to services_path
          end
        else
          if auth
            # signin existing user
            # in the session his user id and the service id used for signing in is stored
            session[:user_id] = auth.user.id
            session[:service_id] = auth.id
          
            flash[:notice] = 'Signed in successfully via ' + @authhash[:provider].capitalize + '.'
            redirect_to root_url
          else
            # this is a new user; show signup; @authhash is available to the view and stored in the sesssion for creation of a new user
            session[:authhash] = @authhash
            render signup_services_path
          end
        end
      else
        flash[:error] =  'Error while authenticating via ' + service_route + '/' + @authhash[:provider].capitalize + '. The service returned invalid data for the user id.'
        redirect_to signin_path
      end
    else
      flash[:error] = 'Error while authenticating via ' + service_route.capitalize + '. The service did not return valid data.'
      redirect_to signin_path
    end
  end
  
  # callback: failure
  def failure
    flash[:error] = 'There was an error at the remote authentication service. You have not been signed in.'
    redirect_to root_url
  end
end