class Student::SessionsController < Devise::SessionsController
  before_filter :configure_sign_in_params, only: [:create]

  def create
    if can?(:create, AttendanceRecord.new)
      self.resource = warden.authenticate!(auth_options)
      @attendance_record = AttendanceRecord.create(student: current_student)
      set_flash_message(:notice, :signed_in) if is_flashing_format?
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      super
    end
  end

  def destroy
    super
  end

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.for(:sign_in) << :attribute
  end
end
