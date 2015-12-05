class ShowtimesController < ApplicationController

	before_filter :fetch_show
	before_filter :require_reservations_auth

	def index
    # TODO: Is this ever used? If not, remove it
	end

	def show
		@showtime = @show.showtimes.includes(:reservations).find(params[:id])
		@confirmed, @waitlist = @showtime.prepare_guest_lists

    respond_to do |format|
      format.html
      format.csv do
        send_data guest_list_as_csv, filename: "Guest list.csv", type: "text/csv"
      end
    end
	end

	private

	def fetch_show
		@show = Show.find(params[:show_id]) if(params[:show_id])
		@show ||= Show.find_by_url_key(params[:url_key]) if(params[:url_key])
		render :not_found if(!@show)
	end

	def require_reservations_auth
		unless @current_user and @current_user.has_permission?(@show, :reservations)
      redirect_to dashboard_path
    end
	end

  def guest_list_as_csv
    require 'csv'

    # TODO: De-duplicate this, see ShowtimeAttendees#index

    confirmed_reserved = @confirmed.map(&:num).sum
    waitlist_reserved  = @waitlist.map(&:num).sum
    total_reserved     = confirmed_reserved + waitlist_reserved
    confirmed_admitted = @showtime.attendees.reserved.confirmed.count
    waitlist_admitted  = @showtime.attendees.reserved.waitlist.count
    walkins_admitted   = @showtime.attendees.walkin.count
    total_admitted     = @showtime.attendees.count
    reservation_counts = @showtime.attendees.group(:reservation_id).count # { id => ct, id => ct }

    CSV.generate do |csv|
      csv << ["Totals"]
      csv << ["", "On List", "Admitted"]
      csv << ["Reserved", confirmed_reserved, confirmed_admitted]
      csv << ["Waitlist", waitlist_reserved, waitlist_admitted]
      csv << ["Walk-ins", "", walkins_admitted]
      csv << ["Total", "", total_admitted]
      csv << ["Seats available", "", @show.seats]
      csv << [""]

      csv << ["Confirmed"]
      csv << ["Name (alphabetical)", "Num reserved", "Num admitted"]
      @confirmed.each do |reservation|
        csv << [
          "#{reservation.lname}, #{reservation.fname}",
          reservation.num,
          reservation_counts[reservation.id] || 0
        ]
      end
      csv << [""]

      csv << ["Waitlist"]
      csv << ["Name (chronological)", "Num reserved", "Num admitted"]
      @waitlist.each do |reservation|
        csv << [
          "#{reservation.lname}, #{reservation.fname}",
          reservation.num,
          reservation_counts[reservation.id] || 0
        ]
      end
    end
  end
end