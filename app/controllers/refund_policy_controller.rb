class RefundPolicyController < SignaturesController

  def new
    if current_user.completed_signatures == 1
      signature = RefundPolicy.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = 'enrollment_agreement'
      super
    else
      redirect_to root_path
    end
  end
end
