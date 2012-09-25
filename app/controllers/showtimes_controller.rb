class ShowtimesController < ApplicationController  
	
	before_filter :force_auth
	before_filter :fetch_show
	before_filter :auth	
	
	def index
	end
	
	
	def show
		@showtime = @show.showtimes.includes(:reservations).find(params[:id])
		@confirmed = []
		@waitlist = []
		count = 0
		#TODO: test this doesn't alter things
		@showtime.reservations.sort_by(&:updated_at).each do |r|
			@waitlist << r and next if count >= @show.cap
			@confirmed << r
			count += r.num
			if count > @show.cap
				#we just passed it, so let's fix the last entry, push the rest to waitlist
				r2 = r.clone
				r.num -= count - @show.cap
				r2.num -= r.num
				@waitlist << r2
			end
		end
	end
	
	private
	
	def fetch_show
		@show = Show.find(params[:show_id]) if(params[:show_id])
		@show ||= Show.find_by_url_key(params[:url_key]) if(params[:url_key])
		render :not_found if(!@show)
	end
	
	def auth
		redirect_to dashboard_path unless @current_user.has_permission?(@show, :reservations)
	end	
end