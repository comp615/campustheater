class NewsletterMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

  default :from => YDC_EMAIL

  def newsletter_email(shows, auditions, announcements, opportunities, request)
  	@shows = shows
  	@auditions = auditions
  	@announcements = announcements
  	@opportunities = opportunities

  	subject = if Time.now.sunday?
			"YDC Newsletter - Week of " + Time.now.strftime("%B %e") + " - " + Time.now.next_week.strftime("%B %e")
		else
			"YDC Newsletter - Week of " + Time.now.strftime("%B %e") + " - " + Time.now.sunday.strftime("%B %e")
		end
    mail(:to => ["charlie.croom@gmail.com"], :subject => subject)
  end
end