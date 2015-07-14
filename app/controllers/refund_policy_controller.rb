class RefundPolicyController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(CodeOfConduct, RefundPolicy, 'enrollment_agreement', :new)
  end
end
