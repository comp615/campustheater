require "spec_helper"

describe ShowtimesController do
  render_views

  describe "#show" do
    before do
      @show = create :show, seats: 10
      @showtime = @show.showtimes.first

      # Several reservations
      @res1 = create :reservation, showtime: @showtime, num: 5
      @res2 = create :reservation, showtime: @showtime, num: 4
      @res3 = create :reservation, showtime: @showtime, num: 3
      @res4 = create :reservation, showtime: @showtime, num: 2

      @house_manager = create :person
      @person = create :person
      create :permission, level: :reservations, person: @house_manager

      sign_in @house_manager
    end

    it "displays the interactive guest list" do
      get :show, show_id: @show.id, id: @showtime.id

      response.status.should eq 200
      response.body.should include "View this guest list as a spreadsheet"
      response.body.should include @res1.lname
      response.body.should include @res2.lname
      response.body.should include @res3.lname
      response.body.should include @res4.lname
      response.body.should include "Seats available"
    end

    it "sends spreadsheet file if .csv format is requested" do
      get :show, show_id: @show.id, id: @showtime.id, format: "csv"
      response.status.should eq 200
      response.body.should include "On List,Admitted"
      response.body.should include "Name (alphabetical),Num reserved,Num admitted"
    end

    it "rejects non-admins" do
      sign_in @person
      get :show, show_id: @show.id, id: @showtime.id
      response.status.should eq 302
      response.should redirect_to dashboard_path # person dashboard
    end

    it "rejects logged-out users" do
      sign_in nil
      get :show, show_id: @show.id, id: @showtime.id
      response.status.should eq 302 # redirected to Yale login page
    end
  end
end