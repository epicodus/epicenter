class EnrollmentAgreementController < SignaturesController

  def new
    super(RefundPolicy, EnrollmentAgreement, 'recurring_payments_option', :index)
  end
end
