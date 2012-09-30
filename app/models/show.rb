class Show < ActiveRecord::Base	
	#TODO: Auto-include
	has_many :showtimes, :dependent => :destroy, :order => "timestamp ASC"
	has_many :show_positions, :dependent => :delete_all, :include => :person
	has_many :permissions, :dependent => :delete_all
	has_many :auditions, :dependent => :destroy
	has_attached_file :poster, :styles => { :medium => "400x400>", :thumb => "150x150>" },				
				:storage => :s3,
     		:s3_credentials => "#{Rails.root}/config/aws.yml",
    		:path => "/shows/:id/poster/:style/:filename"
	
	has_many :directors, :class_name => :ShowPosition, :conditions => {:position_id => 1, :assistant => false}, :include => :person
	
	default_scope :include => :showtimes
	default_scope where(:approved => true)
	
	#TODO: after_update :expire_caches
	#TODO: Make some scopes to get basic information only
	# TODO: Stub out director line and auto-manage
	
	attr_accessible :category, :title, :writer, :tagline, :location, :url_key, :contact, :description, :poster, :flickr_id
	attr_accessible :tix_enabled, :alt_tix, :seats, :cap, :waitlist, :show_waitlist, :freeze_mins_before, :on_sale
	attr_accessible :aud_info
	attr_accessible :showtimes_attributes, :show_positions_attributes, :permissions_attributes
	accepts_nested_attributes_for :showtimes, :allow_destroy => true
	accepts_nested_attributes_for :show_positions, :allow_destroy => true
	accepts_nested_attributes_for :permissions, :allow_destroy => true
	
	# Ensure unique slug
	validates :category, :title, :writer, :location, :contact, :presence, :description, :presence => true, :unless => Proc.new { |s| s.id && s.id < 500 }
	validates_format_of :url_key, :with => /\A[a-z0-9_]+\Z/i, :message => "The url key should contain only letters and numbers", :allow_nil => true
	validates_uniqueness_of :url_key, :allow_nil => true, :case_sensitive => false, :message => "Sorry, the desired url is already taken. Please try another!"
	validates_columns :category
	validates :contact, :email_format => true
	validates :seats, :cap, :freeze_mins_before, :on_sale, :presence => true, :if => Proc.new { |s| s.tix_enabled }
	
	
	def self.shows_in_range(range)
		self.joins(:showtimes).where(:showtimes => {:timestamp => range})
	end
	
	def director
		peeps = self.directors.map{|sp| sp.person ? sp.person.display_name : nil}.compact
		if peeps.length > 1
			peeps[0..-2].join(", ") + " and " + peeps[-1]
		else
			peeps.first.to_s
		end
	end
	
	def cast
		self.show_positions.select {|sp| sp.position_id == 17 && !sp.character.blank?}
	end
	
	def crew
		self.show_positions.select {|sp| sp.position_id != 17 && sp.person}
	end
	
	# All shows till the next Sunday
	def self.this_week
		range = (Time.now .. Time.now.sunday)
		range = (Time.now .. Time.now.next_week) if(Time.now.sunday?)
		
		self.shows_in_range(range)
	end
	
	# All shows which haven't yet closed
	def self.future
		self.joins(:showtimes).where(["showtimes.timestamp >= ?",Time.now]).order("showtimes.timestamp")
	end
	
	def has_opened?
		self.showtimes.first.timestamp.to_time >= Time.now
	end
	
	def has_closed?
		self.showtimes.last.timestamp.to_time < Time.now
	end
	
	def ok_to_ticket?
		self.tix_enabled && self.on_sale.to_time <= Time.now && !self.has_closed?
	end
	
	# Get the OCI term of the show's opening night, can help for categorizing
	def semester
		opens = self.showtimes.first
		if(opens.month < 7)
			opens.year.to_s + "01"
		else
			opens.year.to_s + "03"
		end
	end
	
	# Helper for figuring out if it's this academic semester.
	# @note Expects that shows won't span semesters, only uses opening date
	def this_semester?
		opens = self.showtimes.first.timestamp
		today = Time.now
		
		# TODO: rewrite into a range so it's a bit cleaner
		if(opens.month > 7 && today.month > 7 && today.year == opens.year)
			true
		elsif(opens.month <= 7 && today.month <= 7 && today.year == opens.year)
			true
		else
			false
		end
	end
	
	# Helper for figuring out if the given show is running this week
	def this_week?
		range = (Time.now .. Time.now.sunday)
		range = (Time.now .. Time.now.next_week) if(Time.now.sunday?)
		self.showtimes.detect{ |st| range.cover? st.timestamp }
	end
	
	def self.shows_in_term(oci_term)
		range = self.term_to_range(oci_term)
		self.shows_in_range(range)
	end
	
	private
	
	# Helper function to convert a static oci_term into a rails date range for querying
	# @param oci_term [String] the oci_term to search for, i.e. 201201 = spring 2012, 201103 = fall 2011
	def self.term_to_range(oci_term)
		year = oci_term.slice(0,4).to_i
		if(oci_term.slice(4,2).to_i == 1)
			#spring
			range = (Time.new(year,1,1).. Time.new(year,7,1))
		else
			#fall
			range = (Time.new(year,7,1).. Time.new(year,12,31))
		end
		range
	end
	
end
