describe CodeOfConduct do
  describe "#create_signature_request" do
    it 'returns and stores a signature request id', :vcr do
      student = FactoryGirl.create(:student)
      code_of_conduct = CodeOfConduct.create(student_id: student.id) # Test didn't pass with FactoryGirl, but does otherwise. Has to do with the after_initialize callback.
      expect(code_of_conduct.signature_request_id).to eq 'f788ebdbd9c6e477f642cb6429e3052be3d5954c'
    end

    it 'returns and stores a sign url', :vcr do
      student = FactoryGirl.create(:student)
      code_of_conduct = CodeOfConduct.create(student_id: student.id)
      expect(code_of_conduct.sign_url).to include 'www.hellosign.com'
    end
  end
end
