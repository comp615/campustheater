class ReservationsController < ApplicationController  

	skip_before_filter :force_auth
	before_filter :fetch_show
	before_filter :auth_reservation, :except => [:index, :new, :create]	
	
	# Show all shows for which reservations are currently open or upcoming, also shows user's if logged in
	def index
		# Right now just do new
		redirect_to @show, :notice => "Sorry all showtimes for this show are completely full" and return if !@show.showtimes.detect{|st| !st.is_waitlist_full? }
		@reservation = Reservation.new
		render :edit
	end
	
	#These two methods are for admin viewing of reservations
	def view
		
	end
	
	def overview
	
	end
	
	# Not actually used I think, supersceded by index for routing cleanliness
	def new
		@reservation = Reservation.new
		render :edit
	end
	
	def create
		@reservation = Reservation.new
		params[:reservation][:token] = rand(36**8).to_s(36)
		params[:reservation][:person_id] = @current_user.id if @current_user
		respond_to do |format|
			if @reservation.update_attributes(params[:reservation])
				
				# Tell the ReservationMailer to send a confirmation email
        ReservationMailer.reservation_confirmation_email(@reservation.showtime, @reservation, @reservation.status_line).deliver

				format.html { redirect_to (url_for([@show,@reservation]) + "?auth_code=#{@reservation.token}"), :notice => 'Reservation was successfully created. You should receive an email confirmation shortly with a link to this page.' }
			else
				flash.now[:error] = 'Sorry, there was a problem with the data you entered, please check below and try again!'
				format.html { render :action => "edit" }
			end
		end
	end
	
	# Show a specific reservation. (Requires auth code or login)
	def show
		if request.format == :ics
			res = @reservation
			ical_event = RiCal.Event do |event|
	      event.description = res.showtime.show.title
	      event.dtstart  =   @reservation.showtime.timestamp
	      event.dtend = @reservation.showtime.timestamp + 2.hours
	     	event.location = @reservation.showtime.show.location
	    end
	    filename = "ydc_tickets_" + @reservation.id.to_s + ".ics"
	    send_data(ical_event.export, :filename => filename, :disposition=>"inline; filename=" + filename, :type=>"text/calendar")
	    return
		end
		render :edit
	end
	
	# Show page to change/edit a reservation (Requires auth code or login)
	def edit
	end
	
	# Update an existing reservation (Requires auth code or login)
	def update
		params[:reservation][:person_id] = @current_user.id if @current_user && (!@reservation || !@reservation.person_id)
		respond_to do |format|
			if @reservation.update_attributes(params[:reservation])
				format.html { redirect_to (url_for([@show,@reservation]) + "?auth_code=#{@reservation.token}"), :notice => 'Reservation was successfully updated.' }
			else
				flash.now[:error] = 'Sorry, there was a problem with the data you entered, please check below and try again! You may only make one reservation per email per show'
				format.html { render :action => "edit" }
			end
		end
	end
	
	# Delete a reservation (Requires auth code or login)
	def destroy
		@reservation.destroy
		redirect_to @show, :notice => 'Reservation was successfully deleted.'
	end
	
	private
	
	# auth_code is the new generated string attached to each model
	# auth is the old MD5 hash based on id and email...so used to preserve old addresses
	def fetch_show
		return if !params[:show_id] && params[:auth]
		@show = Show.includes(:showtimes).find(params[:show_id])
		redirect_to @show, :notice => "Sorry this show's tickets can no longer be changed!" if !@show.ok_to_ticket?
	end
	
	def auth_reservation
		params[:id] ||= params[:tix_id]
		if params[:reservation]
			params[:auth_code] ||= params[:reservation][:auth_code]
			params[:reservation].delete(:auth_code)
		end
		@reservation = Reservation.find(params[:id])
		return false unless params[:auth] || @show.showtime_ids.include?(@reservation.showtime_id)
		
		if(params[:auth] == @reservation.generate_MD5)
			# make a token
			@reservation.update_attribute('token', rand(36**8).to_s(36)) unless @reservation.token

			# Redirect them to the new url structure
			@show = @reservation.showtime.show
			redirect_to (url_for([@show,@reservation]) + "?auth_code=#{@reservation.token}"), :notice => "We've updated our website. Please use the new address shown above for future reference!"
		end

		return true if (@current_user && @current_user.has_permission?(@show, :full)) || 
										(@current_user && @reservation.person_id == @current_user.id) ||
										params[:auth_code] == @reservation.token
		
		# Still hanging around? That means it isn't authed
		raise ActionController::RoutingError.new('Not Found')		
	end	

end