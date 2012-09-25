class PeopleController < ApplicationController  

	before_filter :force_auth, :except => [:show, :logout]
	before_filter :verify_user, :except => [:show, :dashboard, :logout]
	before_filter :fetch_user, :except => [:dashboard, :logout]
	
	def show
		# Show public view
		#TODO: SHould we cache people's public profiles?
	end
	
	def dashboard
		#Determine type of user dashboard to show
		@current_user
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
  
  	# If they are coming from the new user flow, take them to the profile takeover page
		if session[:user_flow_entry]
			flash[:notice] = "User info updated successfully! Just one more quick thing."
			redirect_to takeover_edit
		end
	end
	
	def takeover_edit
		# Take note of session[:user_flow_entry], maybe display special help if so since they are in the think of it
	end
	
	def takeover_update
		# This is the end of the signup flow, send them back
		if session[:user_flow_entry]
			flash[:notice] = "Thanks for hanging in there, we'll leave you alone now! Remember you can always manage your profile on the Dashboard tab at left."
			original_page = session[:user_flow_entry]
			session[:user_flow_entry] = nil
			redirect_to original_page
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
		raise ActionController::RoutingError.new('Forbidden')	unless @current_user && (@current_user.id == params[:id] || @current_user.site_admin?)
	end
	
end