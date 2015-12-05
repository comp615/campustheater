class MakePermissionsShowIdNotRequired < ActiveRecord::Migration
  def up
    change_column :permissions, :show_id, :integer, null: true
  end

  def down
    # This hits SQL syntax error when null is set to false. Likely a Rails bug
    # that isn't worth fixing for now.
    change_column :permissions, :show_id, :integer, null: true
  end
end
