class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_params, if: :devise_controller?

  helper_method :current_user, :current_cohort

protected
  def configure_permitted_params
    devise_parameter_sanitizer.for(:invite) do |u|
      u.permit(:name, :email, :cohort_id)
    end
    devise_parameter_sanitizer.for(:accept_invitation) do |u|
      u.permit(:name, :email, :current_cohort_id, :plan_id, :password, :password_confirmation,
             :invitation_token)
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:plan_id, :cohort_id, :name, :email, :password, :password_confirmation, :current_password)
    end
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:plan_id, :cohort_id, :name, :email, :password, :password_confirmation)
    end
  end

  def after_sign_in_path_for(user)
    if user.is_a? Admin
      cohort_code_reviews_path(user.current_cohort)
    elsif user.is_a? Student
      if (user.class_in_session? && !user.plan.recurring? && user.signed_main_documents?) || (user.class_in_session? && user.plan.recurring? && user.signed_main_documents? && user.signed?(PromissoryNote))
        cohort_code_reviews_path(user.cohort)
      else
        signatures_check_path(user)
      end
    end
  end

  def signatures_check_path(user)
    if !user.plan.recurring? && user.signed_main_documents?
      proper_payments_path(user)
    elsif user.plan.recurring? && user.signed?(PromissoryNote)
      proper_payments_path(user)
    elsif user.plan.recurring? && !user.signed?(PromissoryNote) && user.signed_main_documents?
      new_promissory_note_path
    elsif user.signed?(RefundPolicy)
      new_enrollment_agreement_path
    elsif user.signed?(CodeOfConduct)
      new_refund_policy_path
    elsif !user.signed?(CodeOfConduct)
      new_code_of_conduct_path
    else
      proper_payments_path(user)
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
  #authenticate_inviter is used to restrict who can send invitations. We are overriding the devise default
  #behavior as this requires authentication of the same resource as the invited one. Only admins are allowed
  #to send invitations. This requires that the DeviseInvitable::Inviter is added to the Admin model.
  def authenticate_inviter!
    authenticate_admin!(:force => true)
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
end
