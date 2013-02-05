class AdminController < ApplicationController  

	before_filter :verify_user

	def dashboard
		@pending_shows = Show.unscoped.where(:approved => false)
		@pending_takeovers = TakeoverRequest.where(:approved => false).all
		@shows = Show.unscoped.select([:id,:title]).order(:title).all
		@news = News.order(:created_at).all.reverse
	end

	def newsletter
		@shows = Show.readonly.this_week
		@auditions = Audition.future.includes(:show).select{|a| a.show}.group_by(&:show)
		future_show_ids = Show.future.pluck("`shows`.`id`")
		@opportunities = ShowPosition.crew.vacant.where(:show_id => future_show_ids).includes(:show, :position).group_by(&:show)
		@opportunities = @opportunities.select{|show, arr| show.open_date >= Time.now + 11.days && show.open_date <= Time.now + 60.days}.sort_by{|s,arr| s.open_date}


		@announcements = params[:subject] && params[:message] ? params[:subject].zip(params[:message]) : []
		@preview = true
		if params[:send]
			NewsletterMailer.newsletter_email(@shows, @auditions, @announcements, @opportunities).deliver
			redirect_to admin_dashboard_path, :notice => "Email sent"
		else
			render :file => 'newsletter_mailer/newsletter_email.html.erb', :layout => false
		end
	end
	
	def approve_takeover
		req = TakeoverRequest.find(params[:id])
		if req.fulfill
			redirect_to admin_dashboard_path, :notice => "#{req.person.display_name}'s request granted!"
		else
			redirect_to admin_dashboard_path, :error => "There was a problem, please try again..."
		end
	end
	
	def reject_takeover
		req = TakeoverRequest.find(params[:id]) rescue nil
		req.destroy if req
		redirect_to admin_dashboard_path, :notice => "Request Removed!"
	end
	
	def approve_show
		@show = Show.unscoped.find(params[:id])
		@show.approved = true
		@show.archive = params[:archive].to_i == 1
		if @show.save
			redirect_to admin_dashboard_path, :notice => "Show approved!"
		else
			redirect_to admin_dashboard_path, :error => "There was a problem, please try again..."
		end
	end
	
	private
	
	def verify_user
		redirect_to dashboard_path if(!@current_user || !@current_user.site_admin?)
	end
	
end