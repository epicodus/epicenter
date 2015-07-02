class EnrollmentAgreementController < SignaturesController

  def new
    if current_user.completed_signatures == 2
      signature = EnrollmentAgreement.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = 'payment_methods'
      super
    else
      redirect_to root_path
    end
  end
end
