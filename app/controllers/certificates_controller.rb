class CertificatesController < ApplicationController
  def show
    authorize! :read, :certificate
    @student = current_student
    if !@student.completed_internship_course? || !@student.passed_all_code_reviews?
      redirect_to edit_student_registration_path, alert: "Certificate not yet available."
    end
  end
end
