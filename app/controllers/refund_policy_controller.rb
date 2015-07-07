class RefundPolicyController < SignaturesController

  def new
    controller_for_next_page = 'enrollment_agreement'
    super(CodeOfConduct, RefundPolicy, controller_for_next_page)
  end
end
