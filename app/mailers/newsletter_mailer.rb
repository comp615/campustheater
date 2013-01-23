class NewsletterMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

  default :from => YDC_EMAIL

  def newsletter_email(data)
    #@audition = audition
    #mail(:to => audition.email, :subject => "[YDC Site] Audition Confirmation: " + audition.show.title) unless audition.email.blank?
  end
end