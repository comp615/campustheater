class SearchController < ApplicationController  

	def index
		# Make sure we appropriately fill in the dates
		start = DateTime.strptime(params[:start], '%m/%d/%Y') unless params[:start].blank?
		stop = DateTime.strptime(params[:end], '%m/%d/%Y') unless params[:end].blank?
		
		stop ||= Time.now + 2.year if start
		start ||= Time.now - 20.years if stop
		
		# Prefilter the shows by date if given, needed speed optimization
		if !params[:start].blank? || !params[:end].blank?
			show_ids = Showtime.uniq.where(:timestamp => (start..stop)).pluck(:show_id)
		end
		
		# Build up the query based on what we are looking for
		if params[:mode] == "crew"
			return if params[:position_id].blank? && params[:name].blank?
			@results = ShowPosition.scoped.crew.not_vacant.includes(:show,:person)
			@results = @results.where(:show_id => show_ids) if show_ids
			@results = @results.where(:position_id => params[:position_id]) unless params[:position_id].blank?
			@results = @results.joins(:person).where(["CONCAT_WS( ' ', `fname` , `lname` ) LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
		elsif params[:mode] == "actor"
			return if params[:character].blank? && params[:name].blank?
			@results = ShowPosition.scoped.cast.not_vacant.includes(:show,:person)
			@results = @results.where(:show_id => show_ids) if show_ids
			@results = @results.where(:character => params[:character]) unless params[:character].blank?
			@results = @results.joins(:person).where(["CONCAT_WS( ' ', `fname` , `lname` ) LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
		elsif params[:mode] == "show"
			return if params[:name].blank? && params[:start].blank? && params[:end].blank?
			@results = Show.scoped
			@results = @results.where(:id => show_ids) if show_ids
			@results = Show.where(["title LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
		end
		@results
	end
	
	def lookup
		params[:query] = params[:term] if params[:term]
		
		if params[:type] == "people"
			@results = Person.where("CONCAT_WS( ' ', `fname` , `lname` ) LIKE ?", "%#{params[:query]}%")
			respond_to do |format|
		    format.html { render :action => "results" }
		    format.json { render :json => @results.to_json(:only => [:id,:fname,:lname,:college,:year]) }
		  end
		elsif params[:type] == "show"
		 	@results = Show.where("title LIKE ?", "%#{params[:query]}%")
			respond_to do |format|
		    format.html { render :action => "results" }
		    format.json { render :json => @results }
		  end
		end
  end
end