class EnrollmentAgreementController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(RefundPolicy, EnrollmentAgreement, 'payment_options', :new)
  end
end
