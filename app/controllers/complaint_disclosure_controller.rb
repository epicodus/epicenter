class ComplaintDisclosureController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(ComplaintDisclosure)
  end
end
