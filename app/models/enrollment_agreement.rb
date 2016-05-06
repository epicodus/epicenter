class EnrollmentAgreement < Signature

  attr_accessor :sign_url
  after_initialize :create_signature_request_with_template

private

  def create_signature_request_with_template
    signature_request = HelloSign.send_signature_request_with_template(
      test_mode: ENV['HELLO_SIGN_TEST_MODE'],
      client_id: ENV['HELLO_SIGN_CLIENT_ID'],
      template_id: ENV['ENROLLMENT_AGREEMENT_TEMPLATE_ID'],
      subject: 'Sign to accept the Epicodus Enrollment Agreement',
      signers: [
        {
          email_address: student.email,
          name: student.name,
          role: 'Student'
        }
      ],
      custom_fields: {
        student_name: student.name,
        program_start_date: Time.zone.now.to_date
      }
    )
    self.signature_request_id = signature_request.data['signatures'].first['signature_id']
  end
end
