class CodeOfConductController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(nil, CodeOfConduct, 'refund_policy', :new)
  end
end
