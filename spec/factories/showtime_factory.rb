FactoryGirl.define do
  factory :showtime do
    # A Show isn't valid without at least one Showtime; a Showtime isn't valid
    # without a show_id; so they need to be created together.
    # Therefore `create :showtime` will trigger the creation of 2 Showtimes total;
    # if you only want one, instead do `@showtime = create(:show).showtimes.first`
    show
    sequence(:timestamp) { |n| n.days.from_now }
  end
end