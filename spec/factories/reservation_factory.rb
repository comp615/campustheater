FactoryGirl.define do
  factory :reservation do
    showtime

    reservation_type_id 1
    fname "First Name"
    lname "Last Name"
    email "email@example.com"
    num 2
  end
end