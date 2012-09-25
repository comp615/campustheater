class PeopleController < ApplicationController  

	before_filter :force_auth, :except => [:show, :logout]
	before_filter :verify_user, :except => [:show, :dashboard, :logout, :new, :create]
	before_filter :fetch_user, :except => [:dashboard, :logout, :new, :create]
	
	def show
		# Show public view
		#TODO: SHould we cache people's public profiles?
	end
	
	def dashboard
		#Determine type of user dashboard to show
		@shows = Show.unscoped.includes(:showtimes).find(@current_user.permissions.map(&:show_id))
		@permission_map = @current_user.permissions.group_by(&:show_id)
		
		#TODO: Could probably optimize this
		@reservations = @current_user.reservations.includes(:showtime => [:show]).select{|r| r.showtime.timestamp >= Time.now}.sort{|r| r.showtime.timestamp}
		@auditions = @current_user.auditions.where(["`timestamp` > ?",Time.now])
		@similar_people = @current_user.similar_to_me
	end
	
	# TODO: Remove or hookup to a different flow or do something with these edit things
	def edit
		# Take note of self.needs_registration?, lock them in if so, display special info
	end
	
	# New User step 1
	def new
		redirect_to @current_user if @current_user # They must be CAS authed no we're OK
		@current_user = @person = Person.new
	end
	
	# Designed to be indemnipotent in case they refresh the page and re-submit
	def create
		@person = Person.new unless @current_user
		@person.netid = session[:cas_user] unless @current_user
		#TODO: College saving doesn't work, check the form
		if @current_user || @person.update_attributes(params[:person])
			#Let's check to see if they have any recommended people they match. If so, send them there, otherwise take them away
			@person ||= @current_user
			@matches = @person.similar_to_me
			if @matches.length > 0
				render :new_step2
			else
				url = session[:user_flow_entry]
				session[:user_flow_entry] = nil
				redirect_to url
			end			
		else
			render :new, :notice => "There was an error with the data you entered, please try again!"
		end
	end
	
	def takeover_request
		# Asking to match people, let's do it
		# We'll allow multiple requests for a name and let the admin sort it out...
		# TODO:But they cannot have multiple requests for the same name, we'll have to deal with that in the model that finds this
		# TODO: Finalize and implement
		puts @current_user.id
		puts params[:person_ids].inspect
		if session[:user_flow_entry]
			url = session[:user_flow_entry]
			session[:user_flow_entry] = nil
			redirect_to url, :notice => "Request Successful. Enjoy the site!"
		else
			redirect_to dashboard_path, :notice => "Takeover request successful."
		end
	end
	
	def update
		respond_to do |format|
	    if @person.update_attributes(params[:person])
	      format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
	      format.json { respond_with_bip(@person) }
	    else
	      format.html { render :action => "edit" }
	      format.json { respond_with_bip(@person) }
	    end
	  end
	end
	
	def logout
		redirect_to root_path
	end
	
	private
	
	def fetch_user
		@person = Person.find(params[:id])
	end
	
	def verify_user
		puts @current_user.inspect
		raise ActionController::RoutingError.new('Forbidden')	unless @current_user && (@current_user.id == params[:id].to_i || @current_user.site_admin?)
	end
	
end