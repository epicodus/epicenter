class PromissoryNoteController < SignaturesController

  def new
    super(nil, PromissoryNote, 'payment_methods', :new)
  end
end
