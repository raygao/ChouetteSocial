class User < ActiveRecord::Base
  has_many :services
  
  attr_accessible :name, :email, :wallpaper
end
