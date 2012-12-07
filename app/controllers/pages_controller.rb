class PagesController < ApplicationController

	# The page users hit when they first visit in browser.
	def index
		# Select and load active modules from config DB (if any)

		# Load in news posts and other relevant content for display
		@news = News.order("created_at DESC").first(5)

		@modules = []
		@rows = []
		# Shows!
		# TODO: Change this, duh!

		# Group things appropriately. Cannot be more than 2 modules
		@shows = Show.readonly.this_week

		# TODO: Algorithmically re-arrange posters to be in rows of 2

		puts "Condensing #{@shows.length} shows and #{@modules.length} modules"

		if @shows.length + @modules.length <= 3
			@rows = [@shows + @modules]
		elsif @shows.length + @modules.length == 4
			@rows = [@shows.slice!(0,2), @shows + @modules]	# 2 shows / 2 shows/modules
		elsif @shows.length + @modules.length == 5
			@rows = [@shows.slice!(0,2), @shows + @modules]	# 2 shows / 3 shows/modules
		elsif @shows.length + @modules.length == 6
			@rows = [@shows.slice!(0,3), @shows + @modules] # 3 shows / 3 shows/modules
		elsif @shows.length + @modules.length == 7
			if @modules.length >= 1
				@rows = [ @shows.slice!(0,2), @shows.slice!(0,2) + @modules.slice!(0,1), @shows + @modules] # 2 shows / 3 shows(most one module) / 2 shows/modules
			else
				@rows = [ @shows.slice!(0,2), @shows.slice!(0,3), @shows.slice!(0,2) ] # 2 shows / 3 shows(most one module) / 2 shows/modules
			end
		elsif @shows.length + @modules.length == 8	# 3 shows/modules / 2 shows / 3 modules/shows
			if @modules.length >= 2
				@rows = [ @shows.slice!(0,2) + @modules.slice!(0,1), @shows.slice!(0,2), @shows + @modules]
			else
				@rows = [ @shows.slice!(0,3), @shows.slice!(0,2), @shows + @modules]
			end
		else
			#more than 8? Pshew. Good luck
			while @shows.length > 0
				@rows += @shows.slice!(0,2 + @rows.length % 2)
			end
		end

		puts "row config: #{@rows.map{|r| r.length}.inspect}"
	end

	def search

	end

	# Static Page
	def resources
		@page_name = " - Resources"
	end

	# The parameter we recieve is the file that we want to render
	def guides
		# TODO: SHould probably NOINDEX these, or find a better way to get the data out and into the template
		#Be careful with this as it could lead to bad things
		@file = params[:static_file] + ".html"
		raise ActiveRecord::RecordNotFound unless params[:static_file] =~ /\A[\w\-]+\Z/ && FileTest.exists?(Rails.root + "public/static_guides/" + @file)
	end

end