# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120123004159) do

  create_table "auditions", :force => true do |t|
    t.integer   "show_id",                                                      :null => false
    t.timestamp "timestamp",                 :default => '2003-01-01 00:00:00', :null => false
    t.string    "name",       :limit => 100
    t.string    "phone",      :limit => 50
    t.string    "email"
    t.string    "location"
    t.integer   "person_id"
    t.datetime  "created_at"
    t.datetime  "updated_at"
  end

  create_table "board_positions", :force => true do |t|
    t.string   "position"
    t.integer  "year"
    t.integer  "person_id"
    t.string   "extra"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "board_positions", ["person_id"], :name => "index_board_positions_on_person_id"
  add_index "board_positions", ["year"], :name => "index_board_positions_on_year"

  create_table "news", :force => true do |t|
    t.string    "title",      :null => false
    t.string    "poster",     :null => false
    t.timestamp "created_at", :null => false
    t.text      "text",       :null => false
    t.datetime  "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "fname",        :limit => 50,                    :null => false
    t.string   "lname",        :limit => 50,                    :null => false
    t.string   "email"
    t.integer  "year"
    t.string   "college"
    t.string   "pic"
    t.text     "bio"
    t.string   "password"
    t.string   "confirm_code"
    t.boolean  "active",                     :default => false, :null => false
    t.boolean  "email_allow",                                   :null => false
    t.boolean  "site_admin",                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "netid",        :limit => 6
  end

  add_index "people", ["netid"], :name => "index_people_on_netid"

  create_table "permissions", :force => true do |t|
    t.integer  "show_id"
    t.integer  "person_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "permissions", ["person_id"], :name => "index_permissions_on_person_id"
  add_index "permissions", ["show_id"], :name => "index_permissions_on_show_id"

  create_table "positions", :force => true do |t|
    t.string "position", :null => false
  end

  create_table "reservation_types", :force => true do |t|
    t.string "tix_type", :limit => 50, :null => false
  end

  create_table "reservations", :force => true do |t|
    t.string    "fname",          :limit => 50, :null => false
    t.string    "lname",          :limit => 50, :null => false
    t.string    "email",                        :null => false
    t.integer   "num",            :limit => 1,  :null => false
    t.timestamp "updated_at",                   :null => false
    t.integer   "showtime_id",                  :null => false
    t.integer   "ticket_type_id", :limit => 2,  :null => false
    t.datetime  "created_at"
    t.integer   "person_id"
  end

  create_table "show_positions", :force => true do |t|
    t.integer "show_id",                                    :null => false
    t.integer "position_id", :limit => 2,                   :null => false
    t.boolean "assistant",                :default => true, :null => false
    t.string  "character"
    t.integer "person_id",                                  :null => false
  end

  create_table "shows", :force => true do |t|
    t.string   "category",              :limit => 7,  :default => "theater", :null => false
    t.string   "title",                                                      :null => false
    t.string   "writer",                                                     :null => false
    t.string   "tagline"
    t.string   "location",                                                   :null => false
    t.string   "contact",                                                    :null => false
    t.boolean  "auditions_enabled",                                          :null => false
    t.text     "aud_info"
    t.text     "aud_files"
    t.boolean  "public_aud_info",                                            :null => false
    t.text     "description",                                                :null => false
    t.string   "poster"
    t.boolean  "approved",                                                   :null => false
    t.string   "pw",                                                         :null => false
    t.string   "url_key",               :limit => 25
    t.string   "alt_tix"
    t.integer  "seats",                 :limit => 2,                         :null => false
    t.integer  "cap",                   :limit => 2,                         :null => false
    t.boolean  "waitlist",                            :default => false,     :null => false
    t.boolean  "show_waitlist",                       :default => false,     :null => false
    t.boolean  "tix_enabled",                         :default => false,     :null => false
    t.integer  "freeze_mins_before",                  :default => 120,       :null => false
    t.date     "on_sale"
    t.boolean  "archive",                             :default => true,      :null => false
    t.boolean  "archive_reminder_sent",               :default => false,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "showtimes", :force => true do |t|
    t.integer  "show_id",                       :null => false
    t.boolean  "email_sent", :default => false, :null => false
    t.datetime "timestamp"
  end

  add_index "showtimes", ["show_id"], :name => "show_index"

end
