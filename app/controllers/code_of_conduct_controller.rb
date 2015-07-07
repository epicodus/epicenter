class CodeOfConductController < SignaturesController

  def new
    controller_for_next_page = 'refund_policy'
    super(nil, CodeOfConduct, controller_for_next_page)
  end
end
