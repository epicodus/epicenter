class CodeOfConductController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(CodeOfConduct)
  end
end
