class CodeOfConductController < SignaturesController

  before_action :authenticate_student!

  def new
    super(CodeOfConduct)
  end

  def create
    update_signature_request
    render js: "window.location.pathname ='#{new_refund_policy_path}'"
  end
end
