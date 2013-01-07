class ApplicationController < ActionController::Base
  protect_from_forgery
  
	# Add this before filter to force CAS Authentication on all controllers + actions
	before_filter :check_user	
	
	def logged_in?
		!!@current_user
	end
	
	# And their protected methods
	protected
	
	# force auth is always run after check_user, so we might have been successful
	def force_auth
		session[:last_ts] = nil
		CASClient::Frameworks::Rails::Filter.filter self unless @current_user
		# TODO: Put in place to try to avoid errors when coming from a login, might need to be in a seperate filter
		@current_user = Person.where(:netid => session[:cas_user]).first
		raise if !@current_user
	end
	
	def check_user
		 #session[:cas_user] = "cpc2"
		 #@current_user = Person.where(:netid => "cpc2").first

		# first visit, or stale visit, try to gateway auth
		if(!session[:last_ts] && !@current_user)
				CASClient::Frameworks::Rails::GatewayFilter.filter self
		end
		
		session[:last_ts] = Time.now
		
		if(session[:cas_user])
			# User is CAS Authed, try to make an account for them
			# Check if we actually created an account, and if so, redirect them to profile flow
			@current_user = Person.where(:netid => session[:cas_user]).first
			if !@current_user && (controller_name != "people"  || !["new","create","logout"].include?(action_name))
				# This is their first visit, trigger the new user flow
				session[:user_flow_entry] ||= request.url
				redirect_to new_person_path
			end
		end
		
	end
end
