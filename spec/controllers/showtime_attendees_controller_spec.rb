require "spec_helper"

describe ShowtimeAttendeesController do
  render_views

  before do
    @show = create :show, seats: 10
    @showtime = @show.showtimes.first

    # 14 people reserved / on waitlist
    @res1 = create :reservation, showtime: @showtime, num: 5
    @res2 = create :reservation, showtime: @showtime, num: 4
    @res3 = create :reservation, showtime: @showtime, num: 3
    @res4 = create :reservation, showtime: @showtime, num: 2

    # Attendees:
    # 5 from confirmed list
    5.times { @showtime.attendees.create!(reservation_id: @res1.id) }
    # 1 from waitlist
    @showtime.attendees.create!(reservation_id: @res4.id, was_on_waitlist: true)
    # 1 walk-in
    @showtime.attendees.create!

    @house_manager = create :person
    @person = create :person
    create :permission, level: :reservations, person: @house_manager

    sign_in @house_manager
  end

  describe "#index" do
    it "returns JSON of attendance counts" do
      get :index, show_id: @show.id, showtime_id: @showtime.id

      response.status.should eq 200
      json = JSON.parse(response.body)
      json.keys.should eq %w(success confirmed_reserved confirmed_admitted waitlist_reserved waitlist_admitted walkins_admitted total_reserved total_admitted reservation_counts)
      json["confirmed_reserved"].should eq 10
      json["confirmed_admitted"].should eq 5
      json["waitlist_reserved"].should eq 4
      json["waitlist_admitted"].should eq 1
      json["walkins_admitted"].should eq 1
      json["total_admitted"].should eq 7
    end

    it "rejects non-admins" do
      sign_in @person
      get :index, show_id: @show.id, showtime_id: @showtime.id
      response.status.should eq 302
      response.should redirect_to dashboard_path # person dashboard
    end
  end

  describe "#create" do
    it "adds an admittance record attached to a reservation" do
      @showtime.attendees.where(reservation_id: @res2.id).count.should eq 0

      post :create, show_id: @show.id, showtime_id: @showtime.id, reservation_id: @res2.id

      response.status.should eq 200
      response.body.should eq '{"success":true}'
      @showtime.attendees.where(reservation_id: @res2.id).count.should eq 1
    end

    it "adds walk-in if no reservation_id" do
      @showtime.attendees.walkin.count.should eq 1

      post :create, show_id: @show.id, showtime_id: @showtime.id

      response.body.should eq '{"success":true}'
      @showtime.attendees.walkin.count.should eq 2
    end

    it "includes status warnings in the response" do
      # Capacity has been reached
      3.times { @showtime.attendees.create!(reservation_id: @res2.id) }

      post :create, show_id: @show.id, showtime_id: @showtime.id, reservation_id: @res1.id

      response.body.should eq '{"success":true,"reservation_size_exceeded":true,"num_seats_exceeded":true}'
    end

    it "gives error if reservation_id is invalid" do
      expect{ post :create, show_id: @show.id, showtime_id: @showtime.id, reservation_id: 999 }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it "rejects non-admins" do
      sign_in @person
      post :create, show_id: @show.id, showtime_id: @showtime.id
      response.status.should eq 302
      response.should redirect_to dashboard_path # person dashboard
    end
  end

  describe "#destroy" do
    it "destroys an admittance record by reservation_id" do
      @showtime.attendees.where(reservation_id: @res1.id).count.should eq 5

      delete :destroy, show_id: @show.id, showtime_id: @showtime.id, reservation_id: @res1.id

      response.body.should eq '{"success":true}'
      @showtime.attendees.where(reservation_id: @res1.id).count.should eq 4
    end

    it "destroys a walk-in admittance if no reservation_id" do
      @showtime.attendees.walkin.count.should eq 1

      delete :destroy, show_id: @show.id, showtime_id: @showtime.id

      response.body.should eq '{"success":true}'
      @showtime.attendees.walkin.count.should eq 0
    end

    it "gives error if no admittance exists for that reservation_id" do
      ShowtimeAttendee.delete_all
      expect{ delete :destroy, show_id: @show.id, showtime_id: @showtime.id, reservation_id: @res1.id }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it "gives error if reservation_id is invalid" do
      expect{ delete :destroy, show_id: @show.id, showtime_id: @showtime.id, reservation_id: 999 }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it "rejects non-admins" do
      sign_in @person
      delete :destroy, show_id: @show.id, showtime_id: @showtime.id
      response.status.should eq 302
      response.should redirect_to dashboard_path # person dashboard
    end
  end
end