class ComplaintDisclosureController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(ComplaintDisclosure)
  end

  def create
    update_signature_request
    render js: "window.location.pathname ='#{new_enrollment_agreement_path}'"
  end
end
