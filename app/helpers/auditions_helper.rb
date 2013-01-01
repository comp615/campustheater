require 'csv'
module AuditionsHelper

	def auditions_as_csv(auditions)
		CSV.generate do |csv| 
	    auditions.sort_by(&:timestamp).each do |audition|
	    	data = [small_timestamp(audition.timestamp), audition.location]
	    	data += [audition.person.display_name, audition.email, audition.phone] if audition.person
	      csv << data
	    end
	  end
	end
end