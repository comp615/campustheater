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
		
		@people1 = []
		@people2 = []
		# Build up the query based on what we are looking for
		if (params[:mode] == "crew" || params[:header_search]) && (!params[:position_id].blank? || !params[:name].blank?)
			@people1 = ShowPosition.scoped.crew.not_vacant.includes(:show,:person)
			@people1 = @people1.where(:show_id => show_ids) if show_ids
			@people1 = @people1.where(:position_id => params[:position_id]) unless params[:position_id].blank?
			@people1 = @people1.joins(:person).where(["CONCAT_WS( ' ', `fname` , `lname` ) LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
		end
		if (params[:mode] == "actor" || params[:header_search]) && (!params[:character].blank? || !params[:name].blank?)
			@people2 = ShowPosition.scoped.cast.not_vacant.includes(:show,:person)
			@people2 = @people2.where(:show_id => show_ids) if show_ids
			@people2 = @people2.where(:character => params[:character]) unless params[:character].blank?
			@people2 = @people2.joins(:person).where(["CONCAT_WS( ' ', `fname` , `lname` ) LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
		end
		if (params[:mode] == "show" || params[:header_search]) && (!params[:name].blank? || !params[:start].blank? || !params[:end].blank?)
			@shows = Show.scoped
			@shows = @shows.where(:id => show_ids) if show_ids
			@shows = Show.where(["title LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
		end
		@people = @people1 + @people2
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