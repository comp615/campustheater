class ReservationMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

  default :from => YDC_EMAIL
  
  def reservation_time_change_email(showtime,reservation,status)
    @show = showtime.show
    @showtime = showtime
    @reservation = reservation
    @status = status
    mail(:to => @reservation.email, :subject => "[YDC Site] Showtime Change for: " + @show.title, :reply_to => @show.contact)
  end

  def reservation_confirmation_email(showtime,reservation,status)
  	@show = showtime.show
    @showtime = showtime
    @reservation = reservation
    @status = status
    mail(:to => @reservation.email, :subject => "[YDC Site] Reservation Confirmation: " + @show.title, :reply_to => @show.contact)
  end

  def reservation_canceled_email(showtime,reservation)
  	@show = showtime.show
    @showtime = showtime
    @reservation = reservation
    mail(:to => @reservation.email, :subject => "[YDC Site] Show Cancelation Notice: " + show.title, :reply_to => @show.contact)
  end
end