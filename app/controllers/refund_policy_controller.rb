class RefundPolicyController < SignaturesController

  before_action :authenticate_student!

  def new
    super(RefundPolicy)
  end

  def create
    update_signature_request
    if current_student.course.try(:office).try(:name) == 'Online' && current_student.washingtonian?
      render js: "window.location.pathname ='#{new_complaint_disclosure_path}'"
    else
      render js: "window.location.pathname ='#{new_enrollment_agreement_path}'"
    end
  end
end
