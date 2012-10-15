class AdminController < ApplicationController  

	before_filter :verify_user

	def dashboard
		@pending_shows = Show.unscoped.where(:approved => false)
		@pending_takeovers = TakeoverRequest.where(:approved => false).all
		@shows = Show.unscoped.select([:id,:title]).order(:title).all
		@news = News.order(:created_at).all.reverse
	end
	
	def approve_takeover
		req = TakeoverRequest.find(params[:id])
		if req.fulfill
			redirect_to admin_dashboard_path, :notice => "#{req.person.display_name}'s request granted!"
		else
			redirect_to admin_dashboard_path, :notice => "There was a problem, please try again..."
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
			redirect_to admin_dashboard_path, :notice => "There was a problem, please try again..."
		end
	end
	
	private
	
	def verify_user
		redirect_to dashboard_path if(!@current_user || !@current_user.site_admin?)
	end
	
end