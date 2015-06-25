class EnrollmentAgreementController < SignaturesController

  def new
    enrollment_signature = EnrollmentAgreement.create(student_id: current_student.id)
    @sign_url = enrollment_signature.sign_url
  end
end
