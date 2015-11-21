FactoryGirl.define do
  factory :showtime_attendee do
    showtime
    reservation
  end
end