class EnrollmentAgreementController < SignaturesController

  before_filter :authenticate_student!

  def new
    if current_user.plan.recurring?
      super(RefundPolicy, EnrollmentAgreement, 'promissory_note', :new)
    else
      super(RefundPolicy, EnrollmentAgreement, 'payment_methods', :new)
    end
  end
end
