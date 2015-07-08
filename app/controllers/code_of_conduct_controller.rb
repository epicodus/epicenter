class CodeOfConductController < SignaturesController

  def new
    super(nil, CodeOfConduct, 'refund_policy')
  end
end
