class EnrollmentAgreementController < SignaturesController

  def new
    signature = EnrollmentAgreement.create(student_id: current_student.id)
    @sign_url = signature.sign_url
    @controller_for_next_page = 'payment_methods'
    super
  end
end
