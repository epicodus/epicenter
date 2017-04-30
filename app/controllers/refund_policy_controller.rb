class RefundPolicyController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(RefundPolicy)
  end

  def create
    update_signature_request
    if current_student.course.office.name == "Seattle"
      render js: "window.location.pathname ='#{new_complaint_disclosure_path}'"
    else
      render js: "window.location.pathname ='#{new_enrollment_agreement_path}'"
    end
  end
end
