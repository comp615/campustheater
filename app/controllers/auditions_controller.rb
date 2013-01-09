# Sorry, this controller is the messiest. It's bad

class AuditionsController < ApplicationController  
	
	skip_before_filter :force_auth, :only => [:all, :opportunities]
	#before_filter :verify_show_admin, :only => [:new, :create, :destroy]
	#before_filter :verify_permission, :only => [:edit, :update]
	before_filter :fetch_show, :except => [:all, :opportunities]	
	
	# Cast Opportunities
	def all
		@active_nav = :auditions
		@shows = Audition.future.includes(:show).select{|a| a.show}.group_by(&:show)
	end
	
	# Crew opportunities
	# TODO: Optimize to filter out old shows
	# ^ TODO: Auto-prune old shows with vacant positions so they don't end up clogging this query
	def opportunities
		@active_nav = :opportunities
		@opportunities = ShowPosition.crew.vacant.includes(:show, :position)
		@opportunities.select!{|o| o.show && o.show.showtimes.first.timestamp > Time.now }
		@opportunities = @opportunities.group_by(&:display_name)
		# TODO: Replace show.contact with the email of the producer?
	end
	
	def index
		@auditions = [] and return if request.format == :csv && !@current_user.has_permission?(params[:show_id], :auditions)
		@active_nav = :auditions
		@auditions = @show.auditions.select{|a| a.timestamp > Time.now}
		redirect_to '/auditions' if @auditions.blank? && !@current_user.has_permission?(params[:show_id], :auditions)
		@user_audition = @auditions.detect{|a| a.person_id == @current_user.id }

		# Legacy support, check and reassociate audition if given
		if params[:aud_id]
			legacy_aud =  @show.auditions.find(params[:aud_id])
			require 'digest/md5'
			if Digest::MD5.hexdigest(legacy_aud.name) == params[:aud_hash] || legacy_aud.person_id == @current_user.id
				legacy_aud.update_attribute('person_id', @current_user.id) unless !legacy_aud.person_id.blank?
				redirect_to show_auditions_path(@show), :notice => 'We\'ve associated you audition with your account on the new site. You can now access your audition for this show using the URL above or from the My Dashboard link'
			end
		end

		@user_audition ||= {}
	end
	
	#def new
	#	@audition = Audition.new
	#end
	
	def create
		#expect batch processing so figure out what we're iterating on
		# Assume they gave us Eastern Time Zone stuff
		that_date = DateTime.strptime("#{params[:date]} #{params[:start_time]}", '%m/%d/%Y %l:%M%P')
		start = Time.find_zone('Eastern Time (US & Canada)').local(that_date.year, that_date.month, that_date.day, that_date.hour, that_date.minute)
		that_date = DateTime.strptime("#{params[:date]} #{params[:end_time]}", '%m/%d/%Y %l:%M%P')
		stop = Time.find_zone('Eastern Time (US & Canada)').local(that_date.year, that_date.month, that_date.day, that_date.hour, that_date.minute)

		# Validate things here
		# ensure there's no other time in this span, custom validator
		if @show.auditions.where(:timestamp => (start...stop)).count > 0
			#Bad params
			@auditions = @show.auditions.future.includes(:person)
			flash.now[:error] = 'Given audition times conflict with pre-existing auditions.'
			render :action => 'index'
			return
		end

		raise if params[:duration].to_i < 0
		
		while start < stop do
			@show.auditions.build(:timestamp => start, :location => params[:location])	
			start += params[:duration].to_i.minutes	
		end
		
		respond_to do |format|
			if @show.save
				format.html { redirect_to show_auditions_path(@show), :notice => 'Show was successfully updated.' }
				format.json { render :json => {:success => true} }
	      format.js { render :action => "create_success" }
			else
				render :nothing => true
			end
		end
	end
	
	def edit
	end
	
	def update
	
		if params[:commit] == "cancel" || params[:commit] =~ /\d+/
			# user wants to cancel/update, verify params
			if params[:commit] =~ /\d+/ && (params[:phone].blank? || params[:email].blank?)
				redirect_to show_auditions_path(@show), :error => 'Please enter a valid phone and email so the show can contact you'
				return
			end
			
			# If they had an old time
			@old_audition = @show.auditions.where(:person_id => @current_user.id).first
			if @old_audition
				@old_audition.person_id = nil
				@old_audition.phone = nil
				@old_audition.email = nil
				@old_audition.save!
			end
			
			# If they asked for a new time
			if params[:commit] =~ /\d+/
				@audition = @show.auditions.where(:person_id => nil).find(params[:commit])
				@audition.person_id = @current_user.id
				@audition.phone = params[:phone]
				@audition.email = params[:email]
				@audition.save!
			end	
		elsif params[:id]
			raise unless @aud_admin #Only admins
			# single update as from best in place, just assign location?
			@audition = @show.auditions.find(params[:id])
			respond_to do |format|
		    if @audition.update_attributes(params[:audition])
		      format.html { redirect_to(@show, :notice => 'Show was successfully updated.') }
		      format.json { render :json => {:success => true} }
		    else
		      format.html { render :action => "edit" }
		      format.json { render :json => {:error => true} }
		    end
		  end
		  return	
		else
			raise unless @aud_admin #Only admins
			# Mass delete, wish I could have managed this more cleanly
			# @show.audition_ids = params[:auditions].select {|id,values| values[:_destroy] != "1"}.map{|id,values| id}	

			# New way form edit page
			@show.auditions.find(params[:destroy_ids]).each{|a| a.destroy}
			@show.auditions(true)
		 	render :action => "create_success"
			return
		end
		redirect_to show_auditions_path(@show), :notice => 'Audition successfully updated.'
	end
	
	private

	def fetch_show
		# Hack to get the mass-update going, id is actually show_id here
		if params[:show_id].blank? && action_name == "update"
			params[:show_id] = params[:id]
			params.delete(:id)
		end
		
		# Check permissions, if admin, pre-load the people too
		if logged_in? && @current_user.has_permission?(params[:show_id], :auditions)
			@aud_admin = true
			@show = Show.includes(:auditions => [:person]).find(params[:show_id])
		else
			@show = Show.includes(:auditions).find(params[:show_id])
		end
	end	
end
