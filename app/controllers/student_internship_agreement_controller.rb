class StudentInternshipAgreementController < SignaturesController

  before_action :authenticate_student!

  def new
    super(StudentInternshipAgreement)
  end

  def create
    update_signature_request
    StudentInternshipAgreement.create_from_signature_id(params[:signature_id])
    flash[:notice] = "Student Internship Agreement signed"
    render js: "window.location.pathname ='#{course_student_path(current_student.internship_course, current_student)}'"
  end
end
