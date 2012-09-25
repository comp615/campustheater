module ApplicationHelper

	# Expects ordered showtime array, this is usually handled by the model
	def format_showtimes(array)
		start = array.first.timestamp
		stop = array.last.timestamp
		if start.month == stop.month && start.day == stop.day
			str = start.strftime("%B #{start.day.ordinalize}")
		elsif start.month == stop.month
			str = start.strftime("%B %e")
			str += "-" + stop.day.to_s
		else
			str = start.strftime("%B %e")
			str += " - "
			str += stop.strftime("%B %e")
		end
	end
	
	def format_showtime_full(timestamp)
		timestamp.strftime("%b #{timestamp.day.ordinalize} %-l:%M %p")
	end
	
	def format_long_rundates(show)
		start = show.showtimes.first.timestamp
		stop = show.showtimes.last.timestamp
		if start.month == stop.month && start.day == stop.day
			str = start.strftime("%B #{start.day.ordinalize} %Y")
		elsif start.month == stop.month
			str = start.strftime("%B #{start.day.ordinalize}")
			str += "-" + stop.strftime("#{stop.day.ordinalize} %Y")
		else
			str = start.strftime("%B #{start.day.ordinalize}")
			str += " - "
			str += stop.strftime("%B #{stop.day.ordinalize} %Y")
		end
	end
	
	def full_timestamp(time)
		time.strftime("%B #{time.day.ordinalize} at %-l:%M %p")
	end
	
	def small_timestamp(time)
		time.strftime("%b %d %-l:%M %p")
	end
	
	def best_link(show)
		url_for show.url_key.blank? ? show : vanity_path(show.url_key)
	end
	
	def get_reservation_line(show)
		if show.showtimes.length > 0 && Time.now > Time.at(show.showtimes.last.timestamp)
			"Show no longer running"
		elsif !show.tix_enabled && show.alt_tix
			show.alt_tix
		elsif show.tix_enabled && show.on_sale && Time.now > show.on_sale
			link_to "Reserve Tickets", show_reservations_path(show)
		elsif show.tix_enabled
			"Not available till #{show.on_sale}"
		else
			"No data provided"
		end
	end
	
	def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end
  
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
  end
  
   def link_to_cast_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    new_object.position_id = 17
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
  end
end