class PromissoryNoteController < SignaturesController

  before_filter :authenticate_student!

  def new
    super(nil, PromissoryNote, 'payment_methods', :new)
  end
end
