class EnrollmentAgreementController < SignaturesController

  def new
    if params.has_key?(:sig_id)
      refund_policy_signature = Signature.find_by(signature_request_id: params[:sig_id])
      refund_policy_signature.update(is_complete: true)
    end
    if current_user.completed_signatures(RefundPolicy) == 1
      signature = EnrollmentAgreement.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = 'payment_methods'
      super
    else
      redirect_to root_path
    end
  end
end
