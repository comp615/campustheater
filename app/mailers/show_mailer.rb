class ShowMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

  default :from => YDC_EMAIL

  def need_approval_email(show)
    @show = show
    mail(:to => YDC_EMAIL, :subject => "[YDC Site] Approval Request: " + show.title)
  end

  def show_approved_email(show)
    @show = show
    mail(:to => [show.contact,"undergraduateproduction@yale.edu","ycarts@yale.edu"], :subject => "[YDC Site] New Show Approved: " + show.title)
  end

  def show_changed_email(show, changes)
  	@show = show
  	@changes = changes
    mail(:to => ["undergraduateproduction@yale.edu","ycarts@yale.edu"], :subject => "[YDC Site] Show Changed: " + show.title)
  end

end