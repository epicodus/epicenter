class Users::SessionsController < Devise::SessionsController
  include AuthenticateWithOtpTwoFactor
  protect_from_forgery with: :exception, prepend: true, except: :destroy
  prepend_before_action :authenticate_with_otp_two_factor, if: -> { action_name == 'create' && otp_two_factor_enabled? }
  before_action :redirect_if_logged_in

  def create
    params[:user][:email] = params[:user][:email].try(:downcase)
    user = User.find_by(email: params[:user][:email])
    if user.try(:valid_password?, params[:user][:password]) && !user.otp_required_for_login
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
