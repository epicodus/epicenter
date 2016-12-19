class EnrollmentAgreement < Signature

  attr_accessor :sign_url
  before_create :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Enrollment Agreement'
    super
  end
end
