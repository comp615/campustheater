class ShowsController < ApplicationController  
	
	before_filter :force_auth, :except => [:show, :index, :archives]
	before_filter :fetch_show, :only => [:show, :edit, :edit_people, :edit_files, :update, :destroy, :show_showtime, :dashboard]
	before_filter :auth, :except => [:index, :show, :archives, :new, :create, :dashboard]

	cache_sweeper :show_sweeper
	
	
	# upcoming shows, grouped by week, semester, others
	def index
		@active_nav = :calendar
		@page_name = " - Upcoming Shows"
		
		@shows = Show.future
		@this_week = @shows.select{|s| s.this_week?}

		@showtime_data = {}
		@this_week.each {|show| @showtime_data[show.id] = show.showtimes.map {|st| {:id => st.id, :text => st.short_display_time, :cap => show.cap}}}

		@this_semester = (@shows - @this_week).select{|s| s.this_semester?}
		@other = @shows - @this_week - @this_semester
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
		
		s3 = AWS::S3.new
   		s3_bucket = s3.buckets['yaledramacoalition']
   		params[:destroy_files] ||= []
   		s3_bucket.objects.delete(params[:destroy_files].map { |item| "shows/#{@show.id}/misc/#{item}" })
		@s3_objects = s3_bucket.objects.with_prefix("shows/#{@show.id}/misc/")
	end

	def handle_file_upload(data)
	  orig_filename =  data.original_filename
	  filename = sanitize_filename(orig_filename)
	  ext = File.extname(filename).downcase
	  raise unless [".jpg",".jpeg",".gif",".png",".doc",".docx",".xls",".xlsx",".pdf",".txt"].include? ext
	  s3 = AWS::S3.new
   	s3_bucket = s3.buckets['yaledramacoalition']
	  o = s3_bucket.objects["shows/#{@show.id}/misc/" + filename]
		o.write(:file => data.tempfile, :access => :public_read)
		# @s3_objects = s3_bucket.objects.with_prefix("shows/#{@show.id}/misc/")
	  redirect_to show_edit_files_path(@show), :notice => "File uploaded"
	end
	
	def update
		#Process blanks to nils
		params[:show].each {|key,val| val = nil if val.blank? }

		# handle file uploads
		# TODO: move into it's own controlleR?
		if (params[:show][:file])
			handle_file_upload(params[:show][:file])
			return
		end
		
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

				# Format the date properly into a time object and use the current server TS to get UTC offset they meant
				that_date =  DateTime.strptime("#{obj[:date]} #{obj[:time]}", '%m/%d/%Y %l:%M%P')
				obj = { :id => obj[:id], :timestamp => Time.find_zone('Eastern Time (US & Canada)').local(that_date.year, that_date.month, that_date.day, that_date.hour, that_date.minute), :_destroy => obj[:_destroy] }
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

		if !@show.id
			post_create = {}
			post_create[:permissions_attributes] = params[:show][:permissions_attributes]
			params[:show].delete(:permissions_attributes)
		end
		
		#Process on_sale time
		params[:show][:on_sale] = DateTime.strptime(params[:show][:on_sale], '%m/%d/%Y') if params[:show][:on_sale]
		params[:show][:freeze_mins_before] = (params[:show][:freeze_mins_before].to_f * 60.0).to_i if params[:show][:freeze_mins_before]
		
		respond_to do |format|
	    if @show.update_attributes(params[:show])
	    	# Add permissions for this person to the show if they tried to delete them
	    	if !@current_user.site_admin? && !@show.permissions.detect{|sp| sp.person_id == @current_user.id && sp.level == :full}
	    		@show.permissions.create(:person_id => @current_user.id, :level => :full)
	    		@show.save!
	    	end

	    	# If it is a new show, now we can ammend permissions and other related models
	    	if post_create
	    		 @show.update_attributes(post_create)
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

	def sanitize_filename(file_name)
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end

	
	def auth
		return true if @current_user.has_permission?(@show, :full)
		
		# Still hanging around? That means it isn't authed
		raise ActionController::RoutingError.new('Not Found')		
	end	
end
