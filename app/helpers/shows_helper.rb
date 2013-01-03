module ShowsHelper

    # generate nav items for shows#index
    def nav_items_for_index
        items = []
        items << {:link => "#opening", :text => "Opening Soon"} unless @this_week.empty?
        items << {:link => "#this_semester", :text => oci_id_to_text(current_oci_id)} unless @this_semester.empty?
        items << {:link => "#next_semester", :text => oci_id_to_text(next_oci_id)}    unless @other.empty?
        
        (2008..Time.now.year).to_a.reverse.each do |year|
            items << {:link => "##{year.to_s + (year == Time.now.year && Time.now.month < 8 ? "01" : "03")}", :text => year }
        end
        
        items << {:link => "#ancient", :text => "Ancient"}
        
        return items
    end

end