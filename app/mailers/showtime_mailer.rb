class ShowtimeMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

  default :from => YDC_EMAIL
  
  def notify_oup_email(show,showtime)
    @show = show
    @showtime = showtime
    mail(:to => ["undergraduateproduction@yale.edu","ycarts@yale.edu"], :subject => "[YDC Site] Showtime Change for: " + show.title)
  end
end