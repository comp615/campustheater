class Reservation < ActiveRecord::Base	
	require 'digest/md5'
	
	belongs_to :reservation_type
	belongs_to :showtime
	belongs_to :person
	
	validates :fname, :lname, :email, :reservation_type_id, :showtime_id, :presence => true
	validates :email, :email_format => true
	validates :num, :numericality => { :only_integer => true, :greater_than => 0 }
	validate :other_validations
	validates_columns :showtime_id
	
	def show
		self.showtime.show
	end
	
	def show_id
		self.showtime.show_id
	end
	
	def cap
		self.show.cap
	end
	
	def generate_MD5
		# TODO: Figure out what it is
		# Digest::MD5.hexdigest()
	end

	def status_line
		num_before = self.showtime.reservations.where(["updated_at < ?", self.updated_at]).sum(:num) 
		if num_before >= self.show.cap
			"WAITLISTED (Show up anyways as many waitlist spots usually free up)"
		elsif num_before + @reservation.num > @show.cap
			"PARTIALLY RESERVED (#{@show.cap - num_before} CONFIRMED)"
		else
			"CONFIRMED"
		end
	end
	
	def other_validations
		other_showtime_ids = self.show.showtime_ids
		user_other_reservations_count = Reservation.where(:email => self.email, :showtime_id => other_showtime_ids)
		if self.id
		user_other_reservations_count = user_other_reservations_count.where(["id != ?", self.id]).count
		else
		user_other_reservations_count = user_other_reservations_count.where("id IS NOT NULL").count
		end
		if user_other_reservations_count > 0 && 
      errors.add(:email, "cannot make multiple reservations to the same show")
    end
    if num > self.show.cap
    	errors.add(:num, "is too large")
    end
	end
end