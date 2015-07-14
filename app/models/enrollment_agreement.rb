class EnrollmentAgreement < Signature

  attr_accessor :sign_url
  after_initialize :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Enrollment Agreement'
    @file = ENV['ENROLLMENT_AGREEMENT_DOCUMENT_URL']
    super
  end
end
