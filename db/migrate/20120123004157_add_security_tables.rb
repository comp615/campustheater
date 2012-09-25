class AddSecurityTables < ActiveRecord::Migration
  def change
  	create_table :permissions do |t|
      t.integer :show_id, :null => false
      t.integer :person_id, :null => false
      t.enum :level, :limit => [:full, :reservations, :auditions]
      t.timestamps
    end
    add_index :permissions, :show_id
    add_index :permissions, :person_id
    add_column :people, :site_admin, :boolean, :default => false
  end
end
