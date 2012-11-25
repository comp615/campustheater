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

	def self.group_into_blocks(auditions)
		return [] if auditions.length == 0
		return [auditions] if auditions.length == 1
		auditions.sort_by!(&:timestamp)
		last_ts = auditions.first.timestamp
		expected_gap = auditions[1].timestamp - auditions[0].timestamp # Naive...might be improved somehow
		groups = []
		group = []

		# If the next audition is in the expected gap, then push it into this group
		auditions.each do |a|
			if a.timestamp - last_ts <= expected_gap * 3
				group << a
			else
				groups << group
				group = [a]
			end
			last_ts = a.timestamp
		end
		groups << group
		groups
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