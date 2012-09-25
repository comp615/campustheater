class PagesController < ApplicationController

	# The page users hit when they first visit in browser.
	def index
		# Select and load active modules from config DB (if any)
		
		# Load in news posts and other relevant content for display
		@news = News.last(5)
		
		# Shows!
		@shows = Show.last(5)
	end
	
	def search
	
	end
	
	# Static Page
	def resources
		@page_name = " - Resources"
		@page_header_title = "Resources"
	end
	
	# The parameter we recieve is the file that we want to render
	def guides
		# TODO: SHould probably NOINDEX these, or find a better way to get the data out and into the template
		#Be careful with this as it could lead to bad things
		@file = params[:static_file] + ".html"
		raise ActiveRecord::RecordNotFound unless params[:static_file] =~ /\A[\w\-]+\Z/ && FileTest.exists?(Rails.root + "public/static_guides/" + @file)
	end
	
end