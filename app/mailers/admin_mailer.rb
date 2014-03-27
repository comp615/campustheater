class AdminMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)

	default :from => YDC_EMAIL

	def staff_email(people, subject, message)
		recipients = people.pluck(:email)
		mail(:to => recipients, :subject => subject) unless recipients.blank?
	end
end
