class RefundPolicyController < SignaturesController

  def new
    super(CodeOfConduct, RefundPolicy, 'enrollment_agreement', :new)
  end
end
