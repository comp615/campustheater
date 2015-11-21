require "spec_helper"

describe Showtime do
  describe ".prepare_guest_lists" do
    before do
      @show = create :show, seats: 10
      @showtime = create :showtime, show: @show

      # The first three will end up on the Confirmed list, sorted alphabetically
      @res1 = create :reservation, showtime: @showtime, num: 3, lname: "Berry", created_at: 4.days.ago
      @res2 = create :reservation, showtime: @showtime, num: 3, lname: "deer",  created_at: 3.days.ago
      @res3 = create :reservation, showtime: @showtime, num: 3, lname: "Ember", created_at: 2.days.ago
      # res4 runs past the # of seats, so will be split between confirmed and waitlist
      @res4 = create :reservation, showtime: @showtime, num: 3, lname: "candy", created_at: 1.days.ago
      # res5 is entirely on waitlist since no seats are available
      @res5 = create :reservation, showtime: @showtime, num: 3, lname: "Apple", created_at: 0.days.ago
    end

    it "divides reservations into confirmed and waitlist by order of arrival" do
      @showtime.reservations.count.should eq 5
      confirmed, waitlist = @showtime.prepare_guest_lists

      # puts "Confirmed: #{confirmed.map(&:lname)}"
      # puts "Waitlisted: #{waitlist.map(&:lname)}"

      confirmed.count.should eq 4
      confirmed.map{ |r| [r.lname, r.num] }.should eq [
        # Ordered alphabetically (case insensitive)
        [@res1.lname, 3],
        [@res4.lname, 1],
        [@res2.lname, 3],
        [@res3.lname, 3]
      ]

      waitlist.count.should eq 2
      waitlist.map{ |r| [r.id, r.lname, r.num] }.should eq [
        # By order of signup - NOT alphabetical
        [@res4.id, @res4.lname, 2],
        [@res5.id, @res5.lname, 3]
      ]
    end
  end
end