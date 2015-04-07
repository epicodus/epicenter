class RegistrationsController < Devise::RegistrationsController
  def new
    flash[:alert] = "Sign up is only allowed via invitation."
    redirect_to root_path
  end
end
