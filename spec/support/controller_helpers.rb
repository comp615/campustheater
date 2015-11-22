def sign_in(person)
  # ie. assuming "subject" is a controller instance
  subject.instance_variable_set(:@current_user, person)
end