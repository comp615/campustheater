# Sorry, this controller is the messiest. It's bad

class AuditionsController < ApplicationController  
	
	before_filter :force_auth, :except => [:all, :opportunities]
	#before_filter :verify_show_admin, :only => [:new, :create, :destroy]
	#before_filter :verify_permission, :only => [:edit, :update]
	before_filter :fetch_show, :except => [:all, :opportunities]	
	
	# Cast Opportunities
	def all
		@shows = Audition.future.includes(:show).group_by(&:show)
	end
	
	# Crew opportunities
	# TODO: Optimize to filter out old shows
	# ^ TODO: Auto-prune old shows with vacant positions so they don't end up clogging this query
	def opportunities
		@opportunities = ShowPosition.crew.vacant.includes(:show, :position)
		@opportunities.select!{|o| o.show.showtimes.first.timestamp > Time.now }
		@opportunities = @opportunities.group_by(&:display_name)
		# TODO: Replace show.contact with the email of the producer?
	end
	
	def index
		@auditions = @show.auditions.future.includes(:person)
		@user_audition = @auditions.detect{|a| a.person_id == @current_user.id} || {}
	end
	
	#def new
	#	@audition = Audition.new
	#end
	
	def create
		#expect batch processing so figure out what we're iterating on
		start = DateTime.strptime("#{params[:date]} #{params[:start_time]}", '%m/%d/%Y %l:%M%P')
		stop = DateTime.strptime("#{params[:date]} #{params[:end_time]}", '%m/%d/%Y %l:%M%P')
		
		# Validate things here
		# ensure there's no other time in this span, custom validator
		if @show.auditions.where(:timestamp => (start...stop)).count > 0
			#Bad params
			@auditions = @show.auditions.future.includes(:person)
			render :action => 'index', :notice => 'Given audition times conflict with pre-existing auditions.'
			return
		end
		
		while start < stop do
			@show.auditions.build(:timestamp => start, :location => params[:location])	
			start += params[:duration].to_i.minutes	
		end
		
		if @show.save
			redirect_to @show.auditions, :notice => 'Show was successfully updated.'
		else
			render :nothing => true
		end
	end
	
	def edit
	end
	
	def update
	
		if params[:commit] == "cancel" || params[:commit] =~ /\d+/
			# user wants to cancel/update, verify params
			if params[:commit] =~ /\d+/ && (params[:phone].blank? || params[:email].blank?)
				redirect_to show_auditions_path(@show), :notice => 'Please enter a valid phone and email so the show can contact you'
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
			@show.audition_ids = params[:auditions].select {|id,values| values[:_destroy] != "1"}.map{|id,values| id}	
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
			@show = Show.includes(:auditions).find(params[:show_id])
		else
			@show = Show.includes(:auditions => [:person]).find(params[:show_id])
		end
	end	
end