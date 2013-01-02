module ApplicationHelper

	# Expects ordered showtime array, this is usually handled by the model
	def format_showtimes(array)
		start = array.first.timestamp
		stop = array.last.timestamp
		if start.month == stop.month && start.day == stop.day
			str = start.strftime("%B #{start.day.ordinalize}")
		elsif start.month == stop.month
			str = start.strftime("%B %e")
			str += " &ndash; " + stop.day.to_s
		else
			str = start.strftime("%B %e")
			str += " &ndash; "
			str += stop.strftime("%B %e")
		end
		str.html_safe
	end
	
	def format_showtime_full(timestamp)
		timestamp.strftime("%b #{timestamp.day.ordinalize} %-l:%M %p")
	end
	
	def format_long_rundates(show)
		return "" unless show.showtimes.count > 0
		showtimes = show.showtimes.sort_by{|st| st.timestamp}
		start = showtimes.first.timestamp
		stop = showtimes.last.timestamp
		if start.month == stop.month && start.day == stop.day
			str = start.strftime("%b %-d, %Y")
		elsif start.month == stop.month
			str = start.strftime("%b %-d")
			str += " &ndash; " + stop.strftime("%-d, %Y")
		else
			str = start.strftime("%b %-d")
			str += " &ndash; "
			str += stop.strftime("%b %-d, %Y")
		end
		str.html_safe
	end
	
	def full_timestamp(time)
		time.strftime("%B #{time.day.ordinalize} at %-l:%M %p")
	end
	
	def small_timestamp(time)
		time.strftime("%b %d %-l:%M %p")
	end

	# (517) 648-8850
	def format_phone(string)
		return "" if string.blank?
		arr = string.scan(/(\d)/)
		return "" if !arr || arr.empty?
		builder = ""
		arr.slice!(0,1) if arr.first.first == "1"
		return "" if arr.length != 10
		[arr.slice!(0,3).join,arr.slice!(0,3).join,arr.slice!(0,4).join].join("-")
	end
	
	def best_link(show, full_path = false)
		if full_path
			url_for show.url_key.blank? ? show_url(show) : vanity_url(show.url_key)
		else
			url_for show.url_key.blank? ? show : vanity_path(show.url_key)
		end
	end
	
	def square_show_thumb(poster)
	    c = (poster.height(:thumb) > poster.width(:thumb)) ? "poster-vertical" : "poster-horizontal"
	    image_tag poster.url(:thumb), :class => c
	end
	
	def link_to_show_title(show)
       # truncate long titles
       title = (show.archive && show.title.length > 45) ? show.title[0,45] + "..." : show.title
       tag_title = (show.archive && show.title.length > 45) ? show.title : ""
       
       if show.id.blank?
           return "<span title=\"#{show.title}\">#{title}</span>"
       else
           return link_to title, best_link(show), :title => tag_title
       end
	end
	
	def get_reservation_line(show, block = false)
		if show.showtimes.length > 0 && Time.now > Time.at(show.showtimes.last.timestamp)
			"Show no longer running"
		elsif !show.tix_enabled && show.alt_tix
			show.alt_tix
		elsif !show.approved
			"Show not yet approved"
		elsif show.tix_enabled && show.on_sale && Time.now > show.on_sale && !block
			link_to "Reserve Tickets", show_reservations_path(show)
		elsif show.tix_enabled && show.on_sale && Time.now > show.on_sale && block
			render :partial => "shared/show_reservation_form", :locals => {:show => show}
		elsif show.tix_enabled
			"Not available till #{show.on_sale}"
		else
			"No data provided"
		end
	end
	
  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", :class => "remove")
  end
  
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => "add-link")
  end
  
   def link_to_cast_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    new_object.position_id = 17
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => "add-link")
  end
  
  #Helper to load javascript page specific stuff
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  def oci_id_to_text(term)
  	year = term.first(4).to_i
  	term.last(2).to_i == 1 ? "Spring #{year}" : "Fall #{year}"
  end

  def current_oci_id
  	today = Time.now
  	"#{today.year}" + (today.month > 6 ? "03" : "01")
  end

  def next_oci_id
  	today = Time.now
  	today.month > 6 ? "#{today.year + 1}01" : "#{today.year}03"
  end
end