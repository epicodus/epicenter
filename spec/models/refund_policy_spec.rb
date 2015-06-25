describe RefundPolicy do
  describe "#create_signature_request" do
    it 'returns and stores a signature request id', :vcr do
      student = FactoryGirl.create(:student)
      refund_policy = RefundPolicy.create(student_id: student.id)
      expect(refund_policy.signature_request_id).to be_truthy
    end

    it 'returns and stores a sign url', :vcr do
      student = FactoryGirl.create(:student)
      refund_policy = RefundPolicy.create(student_id: student.id)
      expect(refund_policy.sign_url).to include 'www.hellosign.com'
    end
  end
end
