class EnrollmentAgreementController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(RefundPolicy, EnrollmentAgreement, 'payment_methods', :new)
  end
end
