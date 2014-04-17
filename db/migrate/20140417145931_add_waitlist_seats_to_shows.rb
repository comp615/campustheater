class AddWaitlistSeatsToShows < ActiveRecord::Migration
  def change
    add_column :shows, :waitlist_seats, :integer
    Show.update_all('waitlist_seats = seats')
  end
end
