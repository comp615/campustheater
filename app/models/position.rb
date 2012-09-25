class Position < ActiveRecord::Base	
	has_many :show_positions
	has_many :people, :through => :show_positions
	
	def display_name
		self.position
	end
end