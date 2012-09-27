class NewsController < ApplicationController  

	before_filter :verify_user

	# TODO:Maybe eventually build this out?
	def index
	end
	
	# TODO:Maybe let people submit news items?
	def new
	end
	
	def show
		@news = News.find(params[:id])
		render :edit
	end
	
	def edit
		@news = News.find(params[:id])
	end
	
	def create
		@news = News.new
		if @news.update_attributes(params[:news])
			redirect_to admin_dashboard_path, :notice => 'News was successfully created.'
		else
			redirect_to admin_dashboard_path, :notice => 'Sorry, there was a problem with the data you entered, please try again'
		end
	end
	
	def update
		@news = News.find(params[:id])
		respond_to do |format|
	    if @news.update_attributes(params[:news])
	      format.html { redirect_to admin_dashboard_path, :notice => 'News was updated.' }
	      format.json { respond_with_bip(@news) }
	    else
	      format.html { render :action => "edit", :notice => 'Sorry, there was a problem with the data you entered, please try again' }
	      format.json { respond_with_bip(@news) }
	    end
	  end
	end
	
	def destroy
		@news = News.find(params[:id]) rescue nil
		@news.destroy if @news
		redirect_to admin_dashboard_path, :notice => 'News deleted.'
	end
	
	private
	
	def verify_user
		redirect_to root_path if(!@current_user || !@current_user.site_admin?)
	end
	
end