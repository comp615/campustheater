class AddShowtimesReminderSent < ActiveRecord::Migration
  def up
  	add_column :showtimes, :reminder_sent, :boolean
  end

  def down
  	remove_column :showtimes, :reminder_sent, :boolean
  end
end
