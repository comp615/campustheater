class UpdateFromProduction < ActiveRecord::Migration
  def up
    # NOTE: rename_column doesn't preserve auto-increment, so we do it by hand
    execute("ALTER TABLE news CHANGE news_id id int(11) NOT NULL AUTO_INCREMENT")
    rename_column :news, :time, :created_at
    add_column :news, :updated_at, :datetime
    
    execute("ALTER TABLE people CHANGE person_id id int(11) NOT NULL AUTO_INCREMENT")
    remove_column :people, :last_update
    add_attachment :people, :picture
    add_column :shows, :picture_meta,    :text
    add_timestamps :people
    add_column :people, :netid, :string, :limit => 6
    add_index :people, :netid
    change_column :people, :email, :string, :null => true
    change_column :people, :email_allow, :boolean, :default => false
    change_column :people, :year, :integer, :limit => 4, :null => true, :default => nil
    execute("UPDATE people SET `year` = NULL WHERE `year` < 2006")
    change_column :people, :college, :string, :null => true
    change_column :people, :pic, :string, :null => true
    change_column :people, :bio, :text, :null => true, :default => nil
    change_column :people, :password, :string, :null => true #TODO: This should eventually be removed in favor of CAS
    change_column :people, :confirm_code, :string, :null => true
    

    
    execute("ALTER TABLE shows CHANGE show_id id int(11) NOT NULL AUTO_INCREMENT")
    add_column :shows, :flickr_id, :string, :null => true
    rename_column :shows, :poster, :old_poster
    change_column :shows, :old_poster, :text, :null => true, :default => nil
    add_attachment :shows, :poster
    add_column :shows, :poster_meta, :text
    add_timestamps :shows
    rename_column :shows, :type, :category
    rename_column :shows, :freeze, :freeze_mins_before
    execute("ALTER TABLE shows CHANGE history description text NOT NULL")
    remove_column :shows, :aud_date
    remove_column :shows, :aud_loc
    remove_column :shows, :aud_signup
    remove_column :shows, :insta_confirm
    change_column :shows, :tagline, :string, :null => true
    change_column :shows, :pw, :text, :null => true, :default => nil
    change_column :shows, :seats, :integer, :limit => 4, :default => 0
    change_column :shows, :cap, :integer, :limit => 4, :default => 0
    change_column :shows, :approved, :boolean, :default => false
    change_column :shows, :auditions_enabled, :boolean, :default => false
    change_column :shows, :aud_info, :text, :null => true, :default => nil
    change_column :shows, :public_aud_info, :boolean, :default => false
    change_column :shows, :aud_files, :text, :null => true, :default => nil
    change_column :shows, :alt_tix, :string, :null => true
    # The numeric ticket params should default to 0 and not matter because it will be disabled/verified
    change_column :shows, :waitlist, :boolean, :default => false
    change_column :shows, :show_waitlist, :boolean, :default => false
    change_column :shows, :tix_enabled, :boolean, :default => false
    change_column :shows, :freeze_mins_before, :integer, :limit => 4, :default => 120 #2 hours
    change_column :shows, :on_sale, :date, :null => true, :default => nil
    change_column :shows, :archive, :boolean, :default => true
    change_column :shows, :archive_reminder_sent, :boolean, :default => false
    add_column :shows, :accent_color, :enum, :limit => [:red, :yellow, :green, :dark_blue, :blue, :light_blue, :black], :null => true
    
    execute("UPDATE `shows` SET url_key = NULL WHERE url_key NOT REGEXP '^[a-zA-Z0-9_]+$'")
    execute("UPDATE `shows` SET on_sale = NULL WHERE on_sale = '0000-00-00'")
    Show.where(:tix_enabled => true, :on_sale => nil).update_all(:on_sale => Time.now - 1.year)
    
    execute("ALTER TABLE tickets_type CHANGE tix_type_id id int(11) NOT NULL AUTO_INCREMENT")
    rename_table :tickets_type, :reservation_types
    
    execute("ALTER TABLE tickets CHANGE tix_id id int(11) NOT NULL AUTO_INCREMENT")
    rename_column :tickets, :tix_type_id, :reservation_type_id
    rename_column :tickets, :created, :updated_at
    add_column :tickets, :created_at, :datetime
    add_column :tickets, :person_id, :integer
    add_column :tickets, :used, :integer, :default => 0, :null => false
    add_column :tickets, :token, :text, :null => true
    rename_table :tickets, :reservations
    
    execute("ALTER TABLE positions CHANGE pos_id id int(11) NOT NULL AUTO_INCREMENT")
    
    execute("ALTER TABLE show_positions CHANGE show_pos_id id int(11) NOT NULL AUTO_INCREMENT")
    rename_column :show_positions, :pos_id, :position_id
    remove_column :show_positions, :name
    change_column :show_positions, :character, :string, :null => true
    change_column :show_positions, :person_id, :integer, :null => true, :default => nil
    add_column :show_positions, :new_assistant, :enum, :limit => [:Associate,:Assistant], :null => true
    add_column :show_positions, :listing_order, :int, :limit => 2, :default => nil, :null => true
    
    # Migrate the nulls out of show_positions, switch to enum prefixes for "assistant"
    ShowPosition.reset_column_information
    ShowPosition.where(:character => "").update_all(:character => nil)
    ShowPosition.where(:person_id => "").update_all(:person_id => nil)
    ShowPosition.where(:assistant => true).update_all(:new_assistant => :assistant)
    
    remove_column :show_positions, :assistant
    rename_column :show_positions, :new_assistant, :assistant
    ShowPosition.reset_column_information
    
    
    rename_table :show_auditions, :auditions
    execute("ALTER TABLE auditions CHANGE aud_id id int(11) NOT NULL AUTO_INCREMENT")
    remove_column :auditions, :signup_timestamp
    add_column :auditions, :person_id, :integer
    add_timestamps :auditions
    Audition.reset_column_information

    # Migrate people to use nils
    Person.reset_column_information
    Person.all.each do |p|
      p.email = nil if p.email.blank?
      p.year = nil if p.year.blank?
      p.college = nil if p.college.blank?
      p.pic = nil if p.pic.blank?
      p.bio = p.bio.gsub(/<br ?\/?>/, "\r\n").gsub(/[\n\r]+/,"\r\n")
      p.bio = nil if p.bio.blank?
      p.password = nil if p.password.blank?
      p.confirm_code = nil if p.confirm_code.blank?
      if p.lname.blank? || p.fname.blank?
        p.destroy
      else
        p.save!
      end
    end
    
    rename_table :show_showtimes, :showtimes
    execute("ALTER TABLE showtimes CHANGE showtime_id id int(11) NOT NULL AUTO_INCREMENT")
    # Convert to Timestamps
    add_column :showtimes, :timestamp, :datetime
    execute("UPDATE showtimes SET `timestamp` = FROM_UNIXTIME(UNIX_TIMESTAMP(CONCAT_WS(' ', CAST(`date` AS CHAR) , CAST(`time` AS CHAR)))) WHERE id > 0")
    remove_column :showtimes, :date
    remove_column :showtimes, :time
    Showtime.reset_column_information
    
    # Now handle some data cleansing
    # Migrate shows to use nils, hold off cross-table migrations till end to prevent de-syncing
    # Migrate shows to use minutes instead of hours for freeze time
    
    Show.reset_column_information
    
    # Remove vacant ShowPositions for past shows
    # Dump shows with no showtimes or those which aren't archived
    Show.all.each do |s|
      s.show_positions.where("position_id != 17 AND person_id IS NULL").delete_all
      s.destroy if s.showtimes.count == 0 || s.archive == false
    end  

    Show.order("id DESC").each do |s|
      s.url_key = nil if s.url_key.blank?
      s.tagline = nil if s.tagline.blank?
      s.aud_info = nil if s.aud_info.blank?
      s.aud_files = nil if s.aud_files.blank?
      s.poster = nil if s.poster.blank?
      s.alt_tix = nil if s.alt_tix.blank?
      s.on_sale = nil if s.on_sale.blank?
      s.freeze_mins_before = s.freeze_mins_before * 60 # Convert to minutes
      s.description = s.description.gsub(/<br ?\/?>/, "\r\n").gsub(/[\n\r]+/,"\r\n")
      
      # If we can't save, the url_key is probably duplicated, remove it
      if s.showtimes.count == 0
        s.destroy
      else
        s.url_key = nil if !s.valid?
        s.save!
      end
    end 
    
    #TODO: tickets, assign tokens, unnullify column
    
  end

  def down
    # Screw it, let's just call this irreversable, because it basically is
    raise
  end
end
