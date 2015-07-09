class EnrollmentAgreementController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(RefundPolicy, EnrollmentAgreement, 'recurring_payments_option', :index)
  end
end
