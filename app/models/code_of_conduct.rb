class CodeOfConduct < Signature

  attr_accessor :sign_url
  before_create :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Code of Conduct'
    @file = ENV['CODE_OF_CONDUCT_DOCUMENT_URL']
    super
  end
end
