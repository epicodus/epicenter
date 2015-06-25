class RefundPolicy < Signature

  attr_accessor :sign_url
  after_initialize :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Refund Policy'
    @file = '/Users/chris/desktop/test.pdf'
    super
  end
end
