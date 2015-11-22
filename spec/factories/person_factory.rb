FactoryGirl.define do
  factory :person do
    fname "Fname"
    lname "lname"
    email "email@example.com"

    factory :admin_person do
      # Admin IDs are hard-coded, so you can't just set the flag to true.
      # Instead we simply set the id to equal a whitelisted one.
      netid "cpc2"
    end
  end
end