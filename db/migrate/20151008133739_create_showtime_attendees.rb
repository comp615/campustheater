class CreateShowtimeAttendees < ActiveRecord::Migration
  def change
    create_table :showtime_attendees do |t|
      t.references :showtime
      t.references :reservation
      t.boolean :was_on_waitlist
      t.datetime :created_at
    end

    add_index :showtime_attendees, :showtime_id
    add_index :showtime_attendees, :reservation_id
  end
end
