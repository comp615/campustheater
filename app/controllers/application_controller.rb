class ApplicationController < ActionController::Base
  protect_from_forgery

  #TODO: Redo everything below to fit the vision once needed
  
	# Add this before filter to force CAS Authentication on all controllers + actions
	before_filter :check_user	
	
	def trigger_login
		session[:back_to] = request.request_uri
		flash[:notice] = "Please login to view this page"
		redirect_to login_url
	end
	
	def logged_in?
		!!@current_user
	end
	
	# And their protected methods
	protected
	
	def force_auth
		CASClient::Frameworks::Rails::Filter unless @current_user
	end
	
	def check_user
		# first visit, or stale visit, try to gateway auth
		if(!session[:last_ts])
				CASClient::Frameworks::Rails::GatewayFilter
		end
		
		session[:last_ts] = Time.now
		
		if(session[:cas_user])
			# User is CAS Authed, try to make an account for them
			# TODO: Check if we actually created an account, and if so, redirect them to profile flow
			@current_user = Person.where(:netid => session[:cas_user]).first_or_create!
			if !@current_user.has_completed_registration?
				# This is their first visit, trigger the new user flow
				session[:user_flow_entry] = request.url
				redirect_to new_user_flow
			end
		end
		
	end
end
