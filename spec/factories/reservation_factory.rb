FactoryGirl.define do
  factory :reservation do
    showtime

    reservation_type_id 1
    fname "First Name"
    sequence(:lname) { |n| "Student #{n}" }
    sequence(:email) { |n| "email_#{n}@example.com" }
    num 2
  end
end