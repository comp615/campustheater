class MigrateDataAndPhotos < ActiveRecord::Migration
   require 'net/ftp'
   require 'yaml'
		
   def up
   	s3 = AWS::S3.new
   	s3_bucket = s3.buckets['yaledramacoalition']
   	conf = YAML.load_file("#{::Rails.root}/config/ftp.yml")[Rails.env]

	  Net::FTP.open(conf["host"],conf["user"],conf["password"]) do |ftp|
		  #Images sit directly in this directory
		  files = ftp.chdir('people_images')
		  Person.where("`pic` IS NOT NULL").all.first(5).each do |person|
		  	ftp.getbinaryfile(person.pic, "tmp/" + person.pic)
		  	puts "tmp/" + person.pic
		  	person.picture = File.open("#{Rails.root}/tmp/#{person.pic}")
		  	person.save!
		  	File.delete("#{Rails.root}/tmp/#{person.pic}")
		  end
		  #remove_column :people, :pic
		  #reset directory
		  files = ftp.chdir('../')
		  files = ftp.chdir('show_images')
		  
		  #Check to see which folders exist
		  valid_dirs = ftp.nlst.map(&:to_i)
		  
		  Show.where(:id => valid_dirs).first(2).each do |show|
		  	ftp.chdir("#{show.id}")
		  	filelist = ftp.nlst
		  	
		  	# Deal with the poster first
		  	if !show.old_poster.blank? || filelist.include?("small_poster.jpg")
		  		ts = show.old_poster[/[0-9]+/].to_i
		  		ts = ftp.mtime("small_poster.jpg").to_i if show.old_poster.blank?
		  		
		  		ts_range = (ts - 5..ts + 5)
		  		# Figure out which file is the poster since we can't tell
		  		filelist.each do |filename|
		  			next if (filename =~ /\Asmall_/ || filename =~ /\Athumb_/ || filename =~ /\.+\Z/) && filename != "small_poster.jpg"
		  			file_ts = ftp.mtime(filename).to_i
		  			
		  			if ts_range.include? file_ts
		  				# Got it. Lez go
		  				ftp.getbinaryfile(filename, "tmp/" + filename)
					  	puts "Poster: tmp/" + filename
					  	show.poster = File.open("#{Rails.root}/tmp/#{filename}")
					  	show.save!
					  	filelist = filelist - [filename]
					  	break
		  			end
		  		end
		  		  	
		  	end
		  			  	
		  	# Take the rest, we know general format for old thumbs and stuff...dump those
		  	
		  	filelist.each do |filename|
		  		# NO: small_, thumb_
		  		next if filename =~ /\Asmall_/ || filename =~ /\Athumb_/ || filename =~ /\.+\Z/
		  		
		  		# move it over to S3
		  		# upload a file
		  		ftp.getbinaryfile(filename, "tmp/" + filename)
			  	puts "tmp/" + filename
			  	
					basename = "shows/#{show.id}/misc/#{filename}"
					o = s3_bucket.objects[basename]
					o.write(:file => "#{Rails.root}/tmp/#{filename}")
		  	end
		  	
		  	# Switch back so we're ready for next show
		  	ftp.chdir("../")
		  end
		end
		
		# Remove old_poster
		remove_column :shows, :old_poster
  end
  
  def down
  end
end
