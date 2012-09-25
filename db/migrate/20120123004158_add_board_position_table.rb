class AddBoardPositionTable < ActiveRecord::Migration
  def change
  	create_table :board_positions do |t|
      t.string :position
      t.integer :year
      t.references :person
      t.string :extra
      t.timestamps
    end
    add_index :board_positions, :year
    add_index :board_positions, :person_id
  end
end
