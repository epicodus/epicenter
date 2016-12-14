class ComplaintDisclosure < Signature

  attr_accessor :sign_url
  before_create :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Seattle Complaint Disclosure'
    super
  end
end
