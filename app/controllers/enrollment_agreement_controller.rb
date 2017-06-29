class EnrollmentAgreementController < SignaturesController

  before_action :authenticate_student!

  def new
    super(EnrollmentAgreement)
  end

  def create
    update_signature_request
    render js: "window.location.pathname ='#{new_demographic_path}'"
  end
end
