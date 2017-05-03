class EnrollmentAgreementController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(EnrollmentAgreement)
  end

  def create
    update_signature_request
    render js: "window.location.pathname ='#{new_demographic_path}'"
  end
end
