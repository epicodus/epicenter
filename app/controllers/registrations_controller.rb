class RegistrationsController < Devise::RegistrationsController

  def new
    if request.env["devise.mapping"] == Devise.mappings[:company] && !current_user
      super
    else
      redirect_to root_path, alert: 'Sign up is only allowed via invitation.'
    end
  end
end
