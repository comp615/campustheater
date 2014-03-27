class Showtime < ActiveRecord::Base	
	belongs_to :show
	has_many :reservations, :dependent => :destroy
	
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
	
	def is_full?
		self.reservations.sum(:num) >= self.show.seats
	end

	def reservations_frozen?
		Time.now > self.timestamp - self.show.freeze_mins_before.minutes
	end
	
	# Cap waitlist at 2x number of seats
	def is_waitlist_full?
		self.is_full? && (!self.show.waitlist || self.reservations.sum(:num) >= self.show.seats * 2)
	end
	
	def remaining_tickets
		[self.show.seats - self.reservations.sum(:num),0].max
	end
	
end
