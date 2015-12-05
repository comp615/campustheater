FactoryGirl.define do
  factory :permission do
    level :full
    person
    # show can be blank
  end
end