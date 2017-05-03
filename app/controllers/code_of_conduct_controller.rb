class CodeOfConductController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(CodeOfConduct)
  end

  def create
    update_signature_request
    render js: "window.location.pathname ='#{new_refund_policy_path}'"
  end
end
