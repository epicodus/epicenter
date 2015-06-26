describe EnrollmentAgreement do
  describe "#create_signature_request" do
    it 'returns and stores a signature request id', :vcr do
      student = FactoryGirl.create(:student)
      enrollment_agreement = EnrollmentAgreement.create(student_id: student.id)
      expect(enrollment_agreement.signature_request_id).to eq '2b309ac80be001954c7b77bd9305d723c52eca3f'
    end

    it 'returns and stores a sign url', :vcr do
      student = FactoryGirl.create(:student)
      enrollment_agreement = EnrollmentAgreement.create(student_id: student.id)
      expect(enrollment_agreement.sign_url).to include 'www.hellosign.com'
    end
  end
end
