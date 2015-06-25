describe EnrollmentAgreement do
  describe "#create_signature_request" do
    it 'returns and stores a signature request id', :vcr do
      student = FactoryGirl.create(:student)
      enrollment_agreement = EnrollmentAgreement.create(student_id: student.id)
      expect(enrollment_agreement.signature_request_id).to be_truthy
    end

    it 'returns and stores a sign url', :vcr do
      student = FactoryGirl.create(:student)
      enrollment_agreement = EnrollmentAgreement.create(student_id: student.id)
      expect(enrollment_agreement.sign_url).to include 'www.hellosign.com'
    end
  end
end
