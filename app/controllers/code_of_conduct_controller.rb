class CodeOfConductController < SignaturesController

  before_action :authenticate_student!

  def new
    super(CodeOfConduct)
  end

  def create
    update_signature_request
    if current_student.course.try(:description) == 'Fidgetech'
      render js: "window.location.pathname ='#{new_enrollment_agreement_path}'"
    else
      render js: "window.location.pathname ='#{new_refund_policy_path}'"
    end
  end
end
