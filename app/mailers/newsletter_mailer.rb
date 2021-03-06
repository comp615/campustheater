class NewsletterMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

  default :from => YDC_EMAIL

  def newsletter_email(shows, auditions, announcements, opportunities, request)
  	@shows = shows
  	@auditions = auditions
  	@announcements = announcements
  	@opportunities = opportunities
    @request = request

  	subject = if Time.now.sunday?
      time_next_week = Time.now + 7.days
			"YDC Newsletter - Week of " + Time.now.strftime("%B %e") + " - " + time_next_week.strftime("%B %e")
		else
			"YDC Newsletter - Week of " + Time.now.strftime("%B %e") + " - " + Time.now.sunday.strftime("%B %e")
		end
    mail(:to => ["ydc-list@mailman.yale.edu"], :subject => subject)
  end
end