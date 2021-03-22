class CertificatesController < ApplicationController
  def show
    authorize! :read, :certificate
    if current_student
      @student = current_student
      unless @student.completed_internship_course? && @student.passed_all_fulltime_code_reviews?
        redirect_to edit_student_registration_path, alert: "Certificate not yet available."
      end
    elsif current_admin
      @student = Student.find(params[:student_id])
    end
  end
end
