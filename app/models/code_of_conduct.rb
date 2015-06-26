class CodeOfConduct < Signature

  attr_accessor :sign_url
  after_initialize :create_signature_request

private

  def create_signature_request
    @subject = 'Sign to accept the Epicodus Code of Conduct'
    @file = 'http://investors.shopify.com/files/doc_downloads/test.pdf'
    super
  end
end
