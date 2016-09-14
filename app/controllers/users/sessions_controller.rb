class Users::SessionsController < Devise::SessionsController
  before_filter :redirect_if_logged_in

  def create
    params[:user][:email] = params[:user][:email].downcase
    user = User.find_by(email: params[:user][:email])
    if user.try(:valid_password?, params[:user][:password])
      request.env["devise.mapping"] = Devise.mappings[user.class.to_s.downcase.to_sym]
      sign_in user
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      super
    end
  end

private

  def redirect_if_logged_in
    redirect_to after_sign_in_path_for(current_user) if current_user
  end
end
