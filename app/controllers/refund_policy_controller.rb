class RefundPolicyController < SignaturesController

  def new
    signature = RefundPolicy.create(student_id: current_student.id)
    @sign_url = signature.sign_url
    @controller_for_next_page = 'enrollment_agreement'
    super
  end
end
