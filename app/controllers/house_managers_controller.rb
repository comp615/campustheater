class HouseManagersController < ApplicationController
  before_filter :require_admin

  def create
    person = Person.find(params[:person_id])
    permission = Permission.new(
      level: :reservations,
      show_id: nil,
      person_id: person.id
    )

    if permission.save
      redirect_to admin_dashboard_path, notice: "House Manager added successfully."
    else
      redirect_to admin_dashboard_path, alert: "Error adding the new House Manager."
    end
  end

  def destroy
    p = Permission.find(params[:id])
    p.destroy
    redirect_to admin_dashboard_path, notice: "House Manager removed."
  end

  private

  def require_admin
    redirect_to dashboard_path unless @current_user and @current_user.site_admin?
  end
end