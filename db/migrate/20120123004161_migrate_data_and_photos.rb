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
		  Person.where("`pic` IS NOT NULL").all.each do |person|
		  	begin
			  	ftp.getbinaryfile(person.pic, "tmp/" + person.pic)
			  	
			  	File.open("#{Rails.root}/tmp/#{person.pic}") do |file|
			  		person.picture = file
			  		person.save!
			  	end
			 	rescue
			 		puts "unable to transfer person #{person.id} -> #{person.pic}"
				ensure
		  		File.delete("#{Rails.root}/tmp/#{person.pic}") if File.exist?("#{Rails.root}/tmp/#{person.pic}")
		  	end
	  	end
		  remove_column :people, :pic

		  #reset directory
		  files = ftp.chdir('../')
		  files = ftp.chdir('show_images')
		  
		  #Check to see which folders exist
		  valid_dirs = ftp.nlst.map(&:to_i)
		  
		  Show.where(:id => valid_dirs).each do |show|
		  	
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
		  				begin
			  				ftp.getbinaryfile(filename, "tmp/" + filename)
						  	
						  	File.open("#{Rails.root}/tmp/#{filename}") do |file|
							  	show.poster = file
							  	show.save!
							  end
						  	filelist = filelist - [filename]
						  rescue
						  	puts "unable to transfer poster #{show.id} -> #{filename}"
						  ensure
						  		File.delete("#{Rails.root}/tmp/#{filename}") if File.exist?("#{Rails.root}/tmp/#{filename}")
						  end
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
		  		begin
			  		ftp.getbinaryfile(filename, "tmp/" + filename)
				  	
				  	
						basename = "shows/#{show.id}/misc/#{filename}"
						o = s3_bucket.objects[basename]
						o.write(:file => "#{Rails.root}/tmp/#{filename}")
					rescue
						puts "unable to write file for show #{show.id} -> #{filename}"
					ensure
						File.delete("#{Rails.root}/tmp/#{filename}") if File.exist?("#{Rails.root}/tmp/#{filename}")
					end
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
