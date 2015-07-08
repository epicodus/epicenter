class EnrollmentAgreementController < SignaturesController

  def new
    super(RefundPolicy, EnrollmentAgreement, 'payment_method')
  end
end
