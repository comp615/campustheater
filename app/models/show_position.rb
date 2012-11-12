class ShowPosition < ActiveRecord::Base
	belongs_to :show
	belongs_to :person
	belongs_to :position
	after_create :recache_director
	after_update :recache_director
	after_update :cleanup_person, :if => proc {|sp| sp.person_id_was != sp.person_id }
	after_destroy :recache_director
	after_destroy :cleanup_person
	
	validates :person, :character, :presence => true, :if => Proc.new { |sp| sp.position_id == 17 }
	
	scope :vacant, where(:person_id => "")
	scope :not_vacant, where("person_id IS NOT NULL && person_id != 0")
	scope :crew, where("position_id != 17")
	scope :cast, where("position_id = 17")
	
	default_scope :order => "listing_order ASC, position_id ASC, assistant ASC"
	
	def display_name
		if self.cast?
			self.character
		else
			self.assistant ? "#{self.assistant.to_s.capitalize} #{self.position.display_name}" : self.position.display_name
		end
	end
	
	def cast?
		self.position_id == 17
	end
	
	private
	
	#TODO: Build out this method to trigger a recache on self.show.director
	def recache_director
	
	end
	
	# TODO: verify this does what it's supposed to
	def cleanup_old_person
		self.person_was.destroy if self.person_was.show_positions.count == 0 && self.person_was.netid.blank?
	end
	
	def cleanup_person
		self.person.destroy if self.person.show_positions.count == 0 && self.person.netid.blank?
	end
	
end