class Services < ActiveRecord::Migration
  def self.up
    add_column :services, :token, :text
    add_column :services, :token_secret, :text
    add_column :services, :token_refresh, :text
  end

  def self.down
    remove_column :services, :token, :text
    remove_column :services, :token_secret, :text
    remove_column :services, :token_refresh, :text
  end
end
