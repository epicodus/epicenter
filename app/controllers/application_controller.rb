class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_params, if: :devise_controller?

protected
  def configure_permitted_params
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:plan_id, :name, :email, :password, :password_confirmation) }
  end

  def after_sign_in_path_for(user)
    if user.has_payment_method
      payments_path
    elsif user.bank_account.present?
      edit_verification_path
    else
      payment_method_path
    end
  end
end
