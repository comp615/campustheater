class ReservationsController < ApplicationController  

	before_filter :fetch_show
	before_filter :auth_reservation, :except => [:index, :new, :create]	
	
	# Show all shows for which reservations are currently open or upcoming, also shows user's if logged in
	def index
		# Right now just do new
		@reservation = Reservation.new
		render :edit
	end
	
	#These two methods are for admin viewing of reservations
	def view
		
	end
	
	def overview
	
	end
	
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

				format.html { redirect_to (url_for([@show,@reservation]) + "?auth_code=#{@reservation.token}"), :notice => 'Reservation was successfully created. You should recieve an email confirmation shortly with a link to this page.' }
			else
				flash.now[:error] = 'Sorry, there was a problem with the data you entered, please check below and try again!'
				format.html { render :action => "edit" }
			end
		end
	end
	
	# Show a specific reservation. (Requires auth code or login)
	def show
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
				flash.now[:error] = 'Sorry, there was a problem with the data you entered, please check below and try again!'
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
	
	def fetch_show
		@show = Show.includes(:showtimes).find(params[:show_id])
		redirect_to @show if !@show.ok_to_ticket?
	end
	
	def auth_reservation
		@reservation = Reservation.find(params[:id])
		return false unless @show.showtime_ids.include? @reservation.showtime_id
		# 
		return true if (@current_user && @current_user.has_permission?(@show, :full)) || 
										@reservation.person_id == @current_user.id ||
										params[:auth_code] == @reservation.generate_MD5 || 
										params[:auth_code] == @reservation.token
		
		if(params[:auth_code] == @reservation.generate_MD5)
			# Redirect them to the new url structure
			redirect_to [@show,@reservation], :auth_code => @reservation.token
		end
		
		# Still hanging around? That means it isn't authed
		raise ActionController::RoutingError.new('Not Found')		
	end	

end