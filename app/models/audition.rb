class Audition < ActiveRecord::Base	
	belongs_to :show
	belongs_to :person
	
	after_update :update_auditioner
	after_update :update_show
	after_destroy :update_auditioner #They can't destroy it, so show did
	
	validates :location, :presence => true
	
	scope :future, where(["timestamp > ?", Time.now + 10.minutes])
	
	def is_taken?
		!self.person_id.blank?
	end
	
	private
		
	#TODO: check both of these against the *OLD* audition timestamp
	# Notify the auditioner of a change
	def update_auditioner
	end
	
	# Notify the show of a signup or whatever
	def update_show
	end
	
end