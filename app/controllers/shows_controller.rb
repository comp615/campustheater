class ShowsController < ApplicationController  
	
	before_filter :force_auth, :except => [:show, :index, :archives]
	before_filter :fetch_show, :only => [:show, :edit, :edit_people, :edit_files, :update, :destroy, :show_showtime, :dashboard]
	before_filter :auth, :except => [:index, :show, :archives, :new, :create, :dashboard]
	
	
	# upcoming shows, grouped by week, semester, others
	def index
		@active_nav = :calendar
		@page_name = " - Upcoming Shows"
		
		@shows = Show.future
		@this_week = @shows.select{|s| s.this_week?}
		@this_semester = (@shows - @this_week).select{|s| s.this_semester?}
		@other = @shows - @this_week - @this_semester
	end
	
	# Similar to upcoming shows, but just the past ones, optionally grouped by oci_term. I.E. 201203
	def archives
		@active_nav = :calendar
		@page_name = " - Archives"
		
		@term = params[:term] || Time.now.year.to_s + (Time.now.month < 7 ? "01" : "03")
		@shows = Show.where(:archive => true).shows_in_term(@term).select(&:has_closed?)
	end
	
	def show
		# Do something with @show?
		#redirect_to root_url
		@active_nav = :calendar
		@page_name = " - #{@show.title}"
		s3 = AWS::S3.new
   	s3_bucket = s3.buckets['yaledramacoalition']
   	@s3_objects = s3_bucket.objects.with_prefix("shows/#{@show.id}/misc/")
	end

	def dashboard
		@page_name = " - Show Dashboard"
		# People can see this as long as they have SOME permission
		s3 = AWS::S3.new
   	s3_bucket = s3.buckets['yaledramacoalition']
		@s3_objects = s3_bucket.objects.with_prefix("shows/#{@show.id}/misc/")
		raise ActionController::RoutingError.new('Not Found') unless @current_user.has_permission?(@show, nil, true)	
	end
	
	def new
		@show = Show.new
		@page_name = " - New Show"
		render :edit
	end
	
	def create
		@show = Show.new
		@show.approved = false
		update
	end
	
	#TODO: Prompt them on submit if they are altering showtimes or something
	def edit
		@page_name = " - Edit Show"
	end

	def edit_people
		@page_name = " - Edit Show"
	end

	def edit_files
		@page_name = " - Edit Show"
		params[:destroy_files].each { |item| AWS::S3Object.delete "shows/#{@show.id}/misc/#{item}", 'yaledramacoalition' } unless params[:destroy_files].blank?
		s3 = AWS::S3.new
   	s3_bucket = s3.buckets['yaledramacoalition']
		@s3_objects = s3_bucket.objects.with_prefix("shows/#{@show.id}/misc/")
	end
	
	def update
		#Process blanks to nils
		params[:show].each {|key,val| val = nil if val.blank? }
		
		#Process showtimes to timestamps
		if params[:show][:showtimes_attributes].blank? && @show.showtimes.count == 0
			@show = Show.new
			render :action => "edit", :notice => 'You must give at least one showtime'
			return
		end
		if params[:show][:showtimes_attributes]
			params[:show][:showtimes_attributes].each do |key,obj| 
				# Remove it if it doesn't have the needed fields
				if obj[:date].blank? || obj[:time].blank?
					params[:show][:showtimes_attributes].delete(key) 
					next
				end

				obj = { :id => obj[:id], :timestamp => DateTime.strptime("#{obj[:date]} #{obj[:time]}", '%m/%d/%Y %l:%M%P'), :_destroy => obj[:_destroy] }
				params[:show][:showtimes_attributes][key] = obj	
			end
		end
		
		#Process person_ids where applicable
		if params[:show][:show_positions_attributes]
			params[:show][:show_positions_attributes].each do |key,obj|
				
				# Create person if not exists
				if obj[:person_id].blank? && !obj[:name].blank?
					name = obj[:name].split
					person = Person.create!(:fname => name[0], :lname => name[1..-1].join(" "))
					obj[:person_id] = person.id
				end
				obj = { :id => obj[:id], 
								:assistant => obj[:assistant], 
								:position_id => obj[:position_id], 
								:person_id => obj[:name].blank? ? nil : obj[:person_id], 
								:character => obj[:character], 
								:listing_order => obj[:listing_order].blank? ? nil : obj[:listing_order], 
								:_destroy => obj[:_destroy]
							}
				params[:show][:show_positions_attributes][key] = obj

				# Remove it if it doesn't have a position
				params[:show][:show_positions_attributes].delete(key) if obj[:position_id].blank? || (obj[:position_id] == "17" && obj[:character].blank?)
			end
		end
		
		#Process permissions to remove names
		if params[:show][:permissions_attributes]
			params[:show][:permissions_attributes].each do |key,obj|
				params[:show][:permissions_attributes].delete(key) if obj[:person_id].blank?
				obj.delete(:name)
			end
		end
		
		#Process on_sale time
		params[:show][:on_sale] = DateTime.strptime(params[:show][:on_sale], '%m/%d/%Y') if params[:show][:on_sale]
		
		respond_to do |format|
	    if @show.update_attributes(params[:show])
	    	#Add permissions for this person to the show if they tried to delete them
	    	if !@current_user.site_admin? && !@show.permissions.detect{|sp| sp.person_id == @current_user.id && sp.level == :full}
	    		@show.permissions.create(:person_id => @current_user.id, :level => :full)
	    		@show.save!
	    	end

	    	# Tell the ShowMailer to send an approval Email to the admin after save
        ShowMailer.need_approval_email(@show).deliver if params[:id].blank?

	      format.html do 
	      	if params[:id].blank?
	      		redirect_to(show_edit_people_path(@show))
	      	else
	      		redirect_to(show_dashboard_path(@show), :notice => 'Show was successfully updated.')
	      	end
	      end
	      format.json { render :json => {:success => true} }
	      format.js { render :action => "edit_success" }
	    else
	      format.html { render :action => "edit" }
	      format.json { render :json => {:error => true} }
	      format.js { render :nothing => true }
	    end
	  end
	end
	
	def destroy
		@show.destroy
		# Return them to wherever? Admin dash will redirect normal people to user dash
		redirect_to admin_dashboard_path
	end
	
	private
	
	def fetch_show
		params[:id] = params[:show_id] if params[:id].blank?
		@show = Show.unscoped.includes(:show_positions => [:person, :position]).find(params[:id]) if(params[:id])
		@show = Show.unscoped.includes(:show_positions => [:person, :position]).find_by_url_key(params[:url_key]) if(params[:url_key])
		raise ActionController::RoutingError.new('Not Found') unless @show && (@show.approved || @current_user.has_permission?(@show, :full))
	end
	
	def auth
		return true if @current_user.has_permission?(@show, :full)
		
		# Still hanging around? That means it isn't authed
		raise ActionController::RoutingError.new('Not Found')		
	end	
end