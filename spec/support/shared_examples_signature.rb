shared_examples 'signature' do |signature_id|
  describe "#create_signature_request" do
    it 'returns and stores a signature request id', :vcr do
      student = FactoryBot.create(:student)
      signature = described_class.create(student_id: student.id)
      expect(signature.signature_id).to be
      # expect(signature.signature_id).to eq signature_id
    end

    it 'returns and stores a sign url', :vcr do
      student = FactoryBot.create(:student)
      signature = described_class.create(student_id: student.id)
      expect(signature.sign_url).to include 'hellosign.com'
    end
  end
end
