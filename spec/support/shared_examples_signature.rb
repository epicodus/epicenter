shared_examples 'signature' do |signature_request_id|
  describe "#create_signature_request" do
    it 'returns and stores a signature request id', :vcr do
      student = FactoryGirl.create(:student)
      signature = described_class.create(student_id: student.id)
      expect(signature.signature_request_id).to be
    end

    it 'returns and stores a sign url', :vcr do
      student = FactoryGirl.create(:student)
      signature = described_class.create(student_id: student.id)
      expect(signature.sign_url).to include 'hellosign.com'
    end
  end
end
