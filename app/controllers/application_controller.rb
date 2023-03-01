class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_params, if: :devise_controller?

  helper_method :current_user, :current_course

protected
  def configure_permitted_params
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:name, :email, :password, :password_confirmation,
               internships_attributes: [:name, :description, :website, :address,
                                        :interview_location, :ideal_intern, :clearance_required,
                                        :clearance_description, :number_of_students, :location, :hiring,
                                        :mentor_name, :mentor_years, :work_schedule, :projects, :contract,
                                        track_ids: [], course_ids: []])
    end
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    devise_parameter_sanitizer.permit(:invite) do |u|
      u.permit(:name, :email, :course_id)
    end
    devise_parameter_sanitizer.permit(:accept_invitation) do |u|
      u.permit(:email, :current_course_id, :password, :password_confirmation,
             :invitation_token, :legal_name)
    end
    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:course_id, :name, :pronouns, :email, :password, :password_confirmation, :current_password)
    end
  end

  devise_group :user, contains: [:student, :company, :admin]

  def after_sign_in_path_for(user)
    if user.is_a? Admin
      user.otp_required_for_login ? course_path(user.current_course) : new_otp_path
    elsif user.is_a? Company
      company_path(user)
    elsif user.is_a? Student
      if user.signed_main_documents? && cookies[:setup_2fa]
        new_otp_path
      elsif user.signed_main_documents? && user.upfront_payment_due?
        if user.course && user.course.language.name == 'Intro' && Date.today >= user.course.end_date.beginning_of_week
          flash[:alert] = '<strong>You have not yet completed your enrollment.</strong><br> Please make your remaining tuition payment as soon as possible.'
        end
        proper_payments_path(user)
      elsif user.signed_main_documents?
        student_courses_path(user)
      else
        signatures_check_path(user)
      end
    end
  end

  def signatures_check_path(user)
    missing_document = user.documents_required.select { |doc| !user.signed?(doc) }.first
    if missing_document
      public_send('new_' + missing_document.name.underscore + '_path')
    else
      new_demographic_path
    end
  end

  def proper_payments_path(user)
    if user.primary_payment_method.present?
      student_payments_path(user)
    elsif user.bank_accounts.first.present?
      payment_methods_path
    else
      new_payment_method_path
    end
  end

  def current_course
    if current_student
      current_student.course
    elsif current_admin
      current_admin.current_course
    end
  end

  #authenticate_inviter is used to restrict who can send invitations. We are overriding the devise default
  #behavior as this requires authentication of the same resource as the invited one. Only admins are allowed
  #to send invitations. This requires that the DeviseInvitable::Inviter is added to the Admin model.
  def authenticate_inviter!
    authenticate_admin!(:force => true)
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
end
