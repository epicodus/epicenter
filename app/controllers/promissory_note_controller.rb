class PromissoryNoteController < SignaturesController

  def new
    super(nil, PromissoryNote, 'payment_methods', :new)
  end

  def create
    signature = Signature.create(student: current_student)
    signature.update(type: PromissoryNote, signature_request_id: 'upfront_payment', is_complete: true)
    redirect_to root_path
  end
end
