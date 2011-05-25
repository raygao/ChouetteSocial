ChouetteSocial::Application.routes.draw do

  match "/signin" => "services#signin"
  match "/signout" => "services#signout"

  match '/auth/:service/callback' => 'services#create' 
  match '/auth/failure' => 'services#failure'

  resources :services, :only => [:index, :create, :destroy] do
    collection do
      get 'signin'
      get 'signout'
      get 'signup'
      post 'newaccount'
      get 'failure'
    end
  end

  resources :users, :only => [:index] do
    collection do
      get 'test'
      post 'newfeedpost'
      get 'newfeedpost'
      post 'setwallpaper'
      get 'setwallpaper'
    end
  end
  
  resources :feedposts, :only => [:index] do
    collection do
      post 'add_new'
      get 'add_new'
    end
  end

  root :to => "users#index"
end
