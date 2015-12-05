FactoryGirl.define do
  factory :show do
    category "theater"
    title "Some Show"
    writer "Jeffrey M. Jones"
    location "Ezra Stiles Little Theater"
    contact "marshall.pailet@example.edu"
    description "A staged reading in conjunction the Postwar Underground Queer Cinema conference sponsored by the Yale Research Initiative on the History of Sexualities."
    accent_color "dark_blue"

    approved true
    seats 50 # capacity before waitlist
    waitlist true # whether reservations are allowed even if full
    waitlist_seats 10 # how large the waitlist can grow
    cap 5 # max size of a reservation
    tix_enabled true # whether users may reserve a seat
    on_sale 1.day.ago # when users may start making reservations

    # A Show isn't valid without at least one Showtime; A Showtime isn't valid
    # without a show_id; so they need to be created together.
    after(:build) do |show|
      show.showtimes << FactoryGirl.build(:showtime, show: show)
    end
  end
end