class AddShowsPrivateRegiatrationToken < ActiveRecord::Migration
  def up
  	add_column :shows, :private_registration_token, :string
  end

  def down
  	remove_column :shows, :private_registration_token, :string
  end
end