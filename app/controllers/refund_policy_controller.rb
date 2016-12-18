class RefundPolicyController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(RefundPolicy)
  end
end
