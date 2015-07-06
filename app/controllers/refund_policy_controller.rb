class RefundPolicyController < SignaturesController

  def new
    if params.has_key?(:sig_id)
      code_of_conduct_signature = Signature.find_by(signature_request_id: params[:sig_id])
      code_of_conduct_signature.update(is_complete: true)
    end
    if current_student.completed_signatures(CodeOfConduct) == 1
      signature = RefundPolicy.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = 'enrollment_agreement'
      super
    else
      redirect_to root_path
    end
  end
end
