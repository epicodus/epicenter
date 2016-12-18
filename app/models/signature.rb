class Signature < ActiveRecord::Base
  belongs_to :student

private

  def create_signature_request
    student.signatures.where(type: self.class, is_complete: nil).delete_all
    if self.is_a?(EnrollmentAgreement)
      create_enrollment_agreement_signature_request_with_template
    else
      create_signature_request_without_template
    end
    self.signature_request_id = @signature_request.data['signatures'].first['signature_id']
    self.sign_url = HelloSign.get_embedded_sign_url(signature_id: @signature_request.signatures.first.data['signature_id']).sign_url
  end

  def create_enrollment_agreement_signature_request_with_template
    @signature_request = HelloSign.create_embedded_signature_request_with_template(
      test_mode: ENV['HELLO_SIGN_TEST_MODE'],
      client_id: ENV['HELLO_SIGN_CLIENT_ID'],
      template_id: ENV['ENROLLMENT_AGREEMENT_TEMPLATE_ID'],
      subject: @subject,
      signers: [{
        email_address: student.email,
        name: student.name,
        role: 'Student'
      }],
      custom_fields: {
        student_name: student.name,
        sign_date: Time.zone.now.to_date.strftime("%A, %B %d, %Y"),
        program_start_date: student.course.start_date.strftime("%A, %B %d, %Y")
      }
    )
  end

  def create_signature_request_without_template
    @signature_request = HelloSign.create_embedded_signature_request(
    test_mode: ENV['HELLO_SIGN_TEST_MODE'],
    client_id: ENV['HELLO_SIGN_CLIENT_ID'],
    subject: @subject,
    signers: [{
      email_address: student.email,
      name: student.name
    }],
    file_url: [@file]
    )
  end
end
