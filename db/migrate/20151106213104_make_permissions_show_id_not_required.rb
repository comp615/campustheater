class MakePermissionsShowIdNotRequired < ActiveRecord::Migration
  def up
    change_column :permissions, :show_id, :integer, null: true
  end

  def down
    change_column :permissions, :show_id, :integer, null: false
  end
end
