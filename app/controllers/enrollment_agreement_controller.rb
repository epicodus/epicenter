class EnrollmentAgreementController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(EnrollmentAgreement)
  end
end
