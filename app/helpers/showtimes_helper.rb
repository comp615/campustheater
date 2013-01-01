require 'csv'
module ShowtimesHelper

	def reservations_as_csv(confirmed, waitlist)
		CSV.generate do |csv| 
			csv << ["Confirmed"]
	    confirmed.sort_by(&:fname).each do |reservation|
	      csv << [reservation.fname + " " + reservation.lname, reservation.num]
	    end
	    csv << [""]
	    csv << ["Waitlist"]
	    waitlist.each do |reservation|
	      csv << [reservation.fname + " " + reservation.lname, reservation.num]
	    end
	  end
	end
end