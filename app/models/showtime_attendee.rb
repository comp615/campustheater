class ShowtimeAttendee < ActiveRecord::Base
  belongs_to :showtime
  belongs_to :reservation

  scope :reserved, -> { where "reservation_id IS NOT NULL" }
  scope :walkin, -> { where "reservation_id IS NULL" }
  scope :confirmed,  -> { where was_on_waitlist: false }
  scope :waitlist, -> { where was_on_waitlist: true }
end
