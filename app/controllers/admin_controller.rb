class AdminController < ApplicationController  

	before_filter :verify_user

	def dashboard
	
	end
	
	private
	
	def verify_user
		redirect_to login_url if(!@current_user || !@current_user.site_admin?)
	end
	
end