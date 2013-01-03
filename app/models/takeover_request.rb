class TakeoverRequest < ActiveRecord::Base
	belongs_to :person
	belongs_to :requested_person, :class_name => "Person"
	
	def fulfill
		return false if self.requested_person.netid
		
		# Transfer over all the data for the other person
		# They cannot have any auditions or reservations since they have no netid
		self.person.permissions << self.requested_person.permissions
		self.person.show_positions << self.requested_person.show_positions
		self.person.picture ||= self.requested_person.picture
		#We need to reload the requested person or the show positions will be destroyed too
		self.requested_person.reload
		self.requested_person.destroy
		self.approved = true
		self.save
	end	
end