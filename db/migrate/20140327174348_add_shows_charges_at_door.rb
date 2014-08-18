class AddShowsChargesAtDoor < ActiveRecord::Migration
  def up
  	add_column :shows, :charges_at_door, :boolean
  end

  def down
  	remove_column :shows, :charges_at_door, :boolean
  end
end
