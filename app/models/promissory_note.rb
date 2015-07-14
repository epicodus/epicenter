class PromissoryNote < Signature

  attr_accessor :sign_url
  after_initialize :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Promissory Note'
    @file = ENV['PROMISSORY_NOTE_DOCUMENT_URL']
    super
  end
end
