class Person < ActiveRecord::Base	
	require 'net/ldap'

	has_many :show_positions, :dependent => :destroy
	has_many :reservations, :dependent => :nullify
	has_many :permissions, :dependent => :delete_all
	has_many :auditions, :dependent => :destroy
	has_many :takeover_requests, :dependent => :destroy #Outgoing requests, incoming are invisible
	has_attached_file :picture, 
				:styles => { :medium => ["400x400>", :jpg], :thumb => ["150x150>", :jpg] },
				:storage => :s3,
     		:s3_credentials => "#{Rails.root}/config/aws.yml",
    		:path => "/people/:id/picture/:style/:filename"
	
	after_create :populateLDAP
	#TODO: Where appropriate, redirect to user dashboard, check for name matches, etc.
	#TODO: Build out salt,pw stuff to allow them to edit themselves once gone!
	#Write a custom typo/distance algo and something else for nicknames
	
	attr_accessible :fname, :lname, :email, :year, :college, :bio, :email_allow, :picture
	
	validates :year, :numericality => { :only_integer => true, :greater_than_or_equal_to => 2006, :less_than_or_equal_to => Time.now.year + 8 }, :allow_nil => true
	validates :college, :inclusion => { :in => YALE_COLLEGES.flatten }, :allow_nil => true
	validates_format_of :email, :with => /^$|\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
                              :message => "Must enter a valid email address."

	def display_name
		self.fname + " " + self.lname
	end
	
	# Check if the user has permission to admin the given show
	# @param show [Integer] the show id to check (can also be a show object)
	# @param type [Symbol] One of :full, or a different type which is also in the DB
	# @returns Boolean true if current user has permission
	def has_permission?(show,type)
		return true if self.site_admin?
		show_id = show.instance_of?(Show) ? show.id : show.to_i
		if(self.permissions.detect{|perm| perm.show_id == show_id && (perm.level == :full || perm.level == type)})
			true
		else
			false #TODO: Maybe auto redirect to login?
		end
	end
	
	def similar_to_me
		people = []
		people.concat Person.find_all_by_fname_and_lname(self.fname, self.lname) unless self.fname.blank? || self.lname.blank?
		people.concat Person.find_all_by_email(self.email) unless self.email.blank?
		people.concat Person.where(["fname LIKE ? AND lname = ?",self.fname.first(1) + "%", self.lname]) unless self.fname.blank? || self.lname.blank?
		people.select! {|person| person.netid == nil }
		people.uniq - [self] - self.takeover_requests.map{|tor| tor.requested_person}
	end
    
  # Accessors 
  def name
    self.fname.capitalize + " " + self.lname.capitalize
  end
  
  def site_admin?
  	["cpc2","sbt3"].include? self.netid
  end
  
  def needs_registration?
  	self.fname.blank?
  end

protected
	#Todo: Repopulate periodically?
  #populate contact fields from LDAP
  def populateLDAP
    return #Fix this later once we get LDAP or whatever worked out
    #quit if no email or netid to work with
    self.email ||= ''
    return if !self.email.include?('@yale.edu') && !self.netid

    begin
      ldap = Net::LDAP.new( :host =>"directory.yale.edu" , :port =>"389" )

      #set e filter, use netid, then email
      if !self.netid.blank? #netid
        f = Net::LDAP::Filter.eq('uid', self.netid)
      else
        f = Net::LDAP::Filter.eq('mail', self.email)
      end

      b = 'ou=People,o=yale.edu'
      p = ldap.search(:base => b, :filter => f, :return_result => true).first
    
    rescue Exception => e
          logger.debug :text => e
          logger.debug :text => "*** ERROR with LDAP"
          guessFromEmail
    end
  
    self.netid = ( p['uid'] ? p['uid'][0] : '' )
    self.fname = ( p['knownAs'] ? p['knownAs'][0] : '' )
    if self.fname.blank?
      self.fname = ( p['givenname'] ? p['givenname'][0] : '' )
    end
    self.lname = ( p['sn'] ? p['sn'][0] : '' )
    self.email = ( p['mail'] ? p['mail'][0] : '' )
    self.year = ( p['class'] ? p['class'][0].to_i : 0 )
    self.college = ( p['college'] ? p['college'][0] : '' )
    
    self.save!

  end

  # not a yale email, just make best guess at it 
  def guessFromEmail
    name = self.email[ /[^@]+/ ]
    return false if !name
    name = name.split( "." )

    self.fname = name[0].downcase
    self.lname = name[1].downcase || ''
    self.save
  end
	
end