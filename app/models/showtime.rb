class Showtime < ActiveRecord::Base	
	belongs_to :show
	has_many :reservations, :dependent => :destroy
	
	before_update :notify_reservations
	# TODO: Build out
	def notify_reservations
		#self.reservations.each {|r| r.do_something}
	end
	
	def is_full?
		self.reservations.sum(:num) >= self.show.seats
	end
	
	# Cap waitlist at 2x number of seats
	def is_waitlist_full?
		!self.show.waitlist || self.reservations.sum(:num) >= self.show.seats * 2
	end
	
	def remaining_tickets
		[self.show.seats - self.reservations.sum(:num),0].max
	end
	
end
