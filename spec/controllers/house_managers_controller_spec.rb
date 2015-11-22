require "spec_helper"

describe HouseManagersController do
  render_views

  before do
    @person = create :person
    @admin = create :admin_person
  end

  describe "#create" do
    before do
      sign_in @admin
    end

    it "creates a new global Reservations permission for this person" do
      Permission.count.should eq 0

      post :create, person_id: @person.id

      response.should redirect_to admin_dashboard_path
      Permission.count.should eq 1
      p = Permission.first
      p.level.should eq :reservations
      p.global?.should eq true
      p.person.should eq @person
    end

    it "returns 404 if person_id not found" do
      expect{ post :create, person_id: 999 }.to raise_error ActiveRecord::RecordNotFound
      Permission.count.should eq 0
    end

    it "rejects non-admins" do
      sign_in @person
      post :create
      response.should redirect_to dashboard_path # ie. person dashboard, not admin
    end
  end

  describe "#destroy" do
    before do
      @permission = create :permission
      sign_in @admin
    end

    it "fetches and destroys this permission record" do
      Permission.count.should eq 1

      delete :destroy, id: @permission.id

      response.should redirect_to admin_dashboard_path
      Permission.count.should eq 0 # removed
    end

    it "returns 404 if permission id not found" do
      expect{ delete :destroy, id: 999 }.to raise_error ActiveRecord::RecordNotFound
      Permission.count.should eq 1 # not removed
    end

    it "rejects non-admins" do
      sign_in @person
      delete :destroy, id: @permission.id

      response.should redirect_to dashboard_path # ie. person dashboard, not admin
      Permission.count.should eq 1 # not removed
    end
  end
end