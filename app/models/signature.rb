class Signature < ActiveRecord::Base
  belongs_to :student

private

  def create_signature_request
    client = HelloSign::Client.new
    signature_request = client.create_embedded_signature_request(
      test_mode: 1,
      client_id: ENV['HELLO_SIGN_CLIENT_ID'],
      subject: @subject,
      signers: [
        {
          email_address: student.email,
          name: student.name
        }
      ],
      files: [@file]
    )
    signature_id = signature_request.signatures.first.data['signature_id']
    signature_request_id = signature_request.data['signature_request_id']
    self.signature_request_id = signature_request_id
    self.sign_url = client.get_embedded_sign_url(signature_id: signature_id).sign_url
  end
end
