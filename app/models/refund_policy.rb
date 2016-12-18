class RefundPolicy < Signature

  attr_accessor :sign_url
  before_create :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Refund Policy'
    @file = ENV['REFUND_POLICY_DOCUMENT_URL']
    super
  end
end
