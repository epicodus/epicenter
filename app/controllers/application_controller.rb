class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_params, if: :devise_controller?

  helper_method :current_user, :current_cohort

protected
  def configure_permitted_params
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:plan_id, :cohort_id, :name, :email, :password, :password_confirmation) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:plan_id, :cohort_id, :name, :email, :password, :password_confirmation, :current_password) }
  end

  def after_sign_in_path_for(user)
    if user.is_a? Admin
      cohort_assessments_path(user.current_cohort)
    elsif user.is_a? Student
      user.class_in_session? ? cohort_assessments_path(user.cohort) : proper_payments_path(user)
    end
  end

  def proper_payments_path(user)
    if user.primary_payment_method.present?
      payments_path
    elsif user.bank_accounts.first.present?
      payment_methods_path
    else
      new_payment_method_path
    end
  end

  def current_user
    current_student || current_admin
  end

  def current_cohort
    if current_student
      current_student.cohort
    elsif current_admin
      current_admin.current_cohort
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
end
