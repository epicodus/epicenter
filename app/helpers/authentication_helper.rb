module AuthenticationHelper
  def authenticate_student_and_admin
    redirect_to root_path unless student_signed_in? or admin_signed_in?
  end
end
