class RefundPolicyController < SignaturesController

  def new
    refund_signature = RefundPolicy.create(student_id: current_student.id)
    @sign_url = refund_signature.sign_url
  end
end
