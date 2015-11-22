require "spec_helper"

describe AdminController do
  render_views

  before do
    @person = create :person
    @admin = create :admin_person
  end

  describe "GET #dashboard" do
    it "rejects non-admins" do
      sign_in @person
      get :dashboard
      response.should redirect_to dashboard_path # ie. person dashboard, not admin
    end

    it "displays the admin dashboard with all controls" do
      sign_in @admin
      get :dashboard

      response.body.should include "Admin Dashboard"
      response.body.should include "Email all"
      response.body.should include "Pending Show Queue"
      response.body.should include "Pending Name Request Queue"
      response.body.should include "House Managers"
    end
  end
end