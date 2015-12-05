def sign_in(person)
  # ie. assuming "subject" is a controller instance
  subject.instance_variable_set(:@current_user, person)

  # Most controller actions force_auth, meaning that non-logged-in users
  # are redirected to Yale's login pages. For pages that don't force auth,
  # this session var allows non-logged-in users to view the page as normal.
  # So you'll need to call `sign_in nil` on those pages to set the cookie.
  session['last_ts'] = 1.day.ago
end