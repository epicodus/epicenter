class RefundPolicyController < SignaturesController

  before_action :authenticate_student!

  def new
    super(RefundPolicy)
  end

  def create
    update_signature_request
    path = current_student.location == 'SEA' ? new_complaint_disclosure_path : new_enrollment_agreement_path
    render js: "window.location.pathname ='#{path}'"
  end
end
