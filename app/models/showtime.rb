class Showtime < ActiveRecord::Base
	belongs_to :show
	has_many :reservations, :dependent => :destroy
  has_many :attendees, class_name: "ShowtimeAttendee"

	after_update :notify_reservations
	after_create :notify_oup
	after_update :notify_oup
	before_destroy :prevent_last_showtime_deletion
	before_destroy :notify_delete_reservations

	def notify_reservations
		return unless self.timestamp_changed?
		num_before = 0
		self.reservations.order("`updated_at` ASC").each do |r|
			if num_before >= self.show.cap
				status = "WAITLISTED (Show up anyways as many waitlist spots usually free up)"
			elsif num_before + r.num > self.show.cap
				status = "PARTIALLY RESERVED (#{self.show.cap - num_before} CONFIRMED)"
			else
				status = "CONFIRMED"
			end
			ReservationMailer.reservation_time_change_email(self,r,status).deliver
			num_before += r.num
		end
	end

	def prevent_last_showtime_deletion
		return false if self.show && self.show.showtimes.count == 1
	end

	def notify_delete_reservations
		if self.timestamp >= Time.now
			self.reservations.each do |r|
				ReservationMailer.reservation_canceled_email(self, r)
			end
		end
	end

	def self.future
		where(["showtimes.timestamp >= ?",Time.now])
	end

	# hack helper...don't use this, use application_helper instead
	def short_display_time
		self.timestamp.strftime("%b %d %-l:%M %p") + (self.is_full? ? " (Waitlist)" : "")
	end

	def notify_oup
		return unless self.timestamp_changed?
		@show = self.show rescue nil # will error if show can't be found, meaning not approved
		ShowtimeMailer.notify_oup_email(@show,self).deliver if @show && @show.approved
	end

	def reserved_seats
		@reserved_seats ||= self.reservations.sum(:num)
	end

	def is_full?
		self.reserved_seats >= self.show.seats
	end

	def reservations_frozen?
		Time.now > self.timestamp - self.show.freeze_mins_before.minutes
	end

	# Cap waitlist when reserved seats = number of seats + waitlist_seats
	def is_waitlist_full?
		self.is_full? && (!self.show.waitlist || self.reserved_seats >= self.show.total_seats)
	end

	def remaining_tickets
		[self.show.seats - self.reserved_seats,0].max
	end

  # Take all reservations and divide them into a Reserved list and a Waitlist
  # ordered by signup time.
  def prepare_guest_lists
    confirmed = []
    waitlist  = []
    num_total = 0

    reservations.order(:updated_at).each do |r|
      if num_total >= show.seats
        # We're already past capacity. All people join the waitlist.
        waitlist << r
        num_total += r.num
      elsif (num_total + r.num) > show.seats
        # This group puts us past capacity. Split it and waitlist the excess #.
        seats_available = (show.seats - num_total)
        r_waitlisted = r.dup
        r.num = seats_available
        r_waitlisted.id = r.id # having the same id referent is important
        r_waitlisted.num -= seats_available

        confirmed << r
        waitlist << r_waitlisted
        num_total += (r.num + r_waitlisted.num)
      else
        # We're still within capacity.
        confirmed << r
        num_total += r.num
      end
    end

    [
      confirmed.sort_by{ |r| r.lname.downcase },
      waitlist # waitlist stays in order reserved
    ]
  end

	#### New code added by steve@commonmedia.com March 2013.

	# Find showtimes by semester and academic year.
	YEAR_START_MONTH = 8 # August is in the second semester, July is in the first

	def self.semester_start
		today = Date.today
		if today.month >= YEAR_START_MONTH
			Date.new today.year, YEAR_START_MONTH, 1
		else
			Date.new today.year, 1, 1
		end
	end

	def self.semester_end
		today = Date.today
		if today.month >= YEAR_START_MONTH
			Date.new today.year + 1, 1, 1
		else
			Date.new today.year, YEAR_START_MONTH, 1
		end
	end

	def self.year_start
		today = Date.today
		if today.month >= YEAR_START_MONTH
			Date.new today.year, YEAR_START_MONTH, 1
		else
			Date.new today.year - 1, YEAR_START_MONTH, 1
		end
	end

	def self.year_end
		today = Date.today
		if today.month >= YEAR_START_MONTH
			Date.new today.year + 1, YEAR_START_MONTH, 1
		else
			Date.new today.year, YEAR_START_MONTH, 1
		end
	end

	def self.this_semester
		where('timestamp BETWEEN ? AND ?', self.semester_start, self.semester_end)
	end

	def self.this_year
		where('timestamp BETWEEN ? AND ?', self.year_start, self.year_end)
	end

	def self.upcoming
		self.future
	end

	def future?
		self.timestamp > Time.zone.now
	end

	def past?
		self.timestamp < Time.zone.now
	end

	####

end
