class ShowtimeAttendeesController < ApplicationController

  before_filter :require_reservations_auth
	before_filter :fetch_show
  before_filter :fetch_showtime

	def index
    # Fetch counts for # confirmed, # waitlist, total admitted, etc.
    # We take these wholesale from the database and don't double-check that the
    # # of confirmed vs. waitlist is sane.

    @confirmed, @waitlist = @showtime.prepare_guest_lists

    # TODO: De-duplicate this, see Showtimes#guest_list_as_csv

    confirmed_reserved = @confirmed.map(&:num).sum
    waitlist_reserved  = @waitlist.map(&:num).sum
    total_reserved     = confirmed_reserved + waitlist_reserved
    confirmed_admitted = @showtime.attendees.reserved.confirmed.count
    waitlist_admitted  = @showtime.attendees.reserved.waitlist.count
    walkins_admitted   = @showtime.attendees.walkin.count
    total_admitted     = @showtime.attendees.count
    reservation_counts = @showtime.attendees.group(:reservation_id).count # { id => ct, id => ct }

    render json: {
      success: true,
      confirmed_reserved: confirmed_reserved,
      confirmed_admitted: confirmed_admitted,
      waitlist_reserved: waitlist_reserved,
      waitlist_admitted: waitlist_admitted,
      walkins_admitted: walkins_admitted,
      total_reserved: confirmed_reserved + waitlist_reserved,
      total_admitted: total_admitted,
      reservation_counts: reservation_counts
    }
	end

	def create
    @showtime.attendees.create!(
      reservation_id: params[:reservation_id],  # this may be nil (if walk-in)
      was_on_waitlist: params[:was_on_waitlist] # this may be nil (if walk-in)
    )

    response = { success: true }

    if @reservation
      num_attending = @showtime.attendees.where(reservation_id: @reservation.id).count
      @reservation.used = num_attending; @reservation.save!
      response[:reservation_size_exceeded] = true if num_attending > @reservation.num
    end

    if @showtime.attendees.count > @showtime.show.seats
      response[:num_seats_exceeded] = true
    end

    render json: response
	end

  def destroy
    if @reservation
      @showtime.attendees.where(reservation_id: @reservation.id).last.destroy

      num_attending = @showtime.attendees.where(reservation_id: @reservation.id).count
      @reservation.used = num_attending; @reservation.save!
    else
      @showtime.attendees.walkin.last.destroy
    end

    render json: { success: true }
  end

	private

	def fetch_show
		@show = Show.find(params[:show_id])
	end

  def fetch_showtime
    @showtime = @show.showtimes.find(params[:showtime_id])
  end

  def fetch_reservation
    if params[:reservation_id]
      @reservation = @showtime.reservations.find(params[:reservation_id])
    end
  end

	def require_reservations_auth
		redirect_to dashboard_path unless @current_user.has_permission?(@show, :reservations)
	end
end