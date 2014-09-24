class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_params, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    flash[:notice] = "Access denied!"
    redirect_to root_path
  end

protected
  def configure_permitted_params
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :email, :password, :password_confirmation) }
  end

  def after_sign_in_path_for(user)
    landing_page_path
    # if user.bank_account.nil?
    #   new_bank_account_path
    # elsif !user.bank_account.verified
    #   edit_verification_path
    # else
    #   payments_path
    # end
  end
end
