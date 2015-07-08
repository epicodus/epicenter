class RefundPolicyController < SignaturesController

  def new
    super(CodeOfConduct, RefundPolicy, 'enrollment_agreement')
  end
end
