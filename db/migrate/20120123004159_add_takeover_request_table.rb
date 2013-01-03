class AddTakeoverRequestTable < ActiveRecord::Migration
  def change
  	create_table :takeover_requests do |t|
      t.references :person, :null => false
      t.references :requested_person, :null => false
      t.boolean :approved, :null => false, :default => false
      t.timestamps
    end
    add_index :takeover_requests, :person_id
  end
end
