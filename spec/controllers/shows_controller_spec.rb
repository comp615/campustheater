require "spec_helper"

describe ShowsController do
  render_views

  before do
    @site_admin = create :admin_person
    @person = create :person
    sign_in nil
  end

  describe "#show" do
    before do
      @show = create :show, seats: 10
      3.times { create :showtime, show: @show }
    end

    it "displays the show details (no user required)" do
      get :show, id: @show.id

      response.status.should eq 200
      response.body.should include "Sign In" # no user is logged in
      response.body.should include "Performances"
      response.body.should include "Reservations"
      response.body.should_not include "Guest list"
    end

    it "displays the show details (normal user logged in)" do
      sign_in @person
      get :show, id: @show.id

      response.body.should_not include "Sign In" # user is logged in
      response.body.should include "Performances"
      response.body.should include "Reservations"
      response.body.should_not include "Guest list"
    end

    specify "when admin, it also displays links to guest list" do
      sign_in @site_admin
      get :show, id: @show.id

      response.body.should include "Guest list"
    end
  end
end