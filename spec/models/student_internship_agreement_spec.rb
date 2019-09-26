describe StudentInternshipAgreement do
  it_behaves_like 'signature', '6e5a020640d5543b6950ea229fd0e96a'

  describe '.create_from_signature_id' do
    let(:internship_course) { FactoryBot.create(:internship_course) }
    let!(:code_review) { FactoryBot.create(:code_review, title: 'Sign internship agreement', course: internship_course, submissions_not_required: true) }
    let(:student) { FactoryBot.create(:student, email: 'example@example.com', courses: [internship_course]) }
    let(:signature) { FactoryBot.create(:completed_student_internship_agreement, student: student) }
    let(:score) { FactoryBot.create(:passing_score) }

    it 'marks code review as passed', :stub_mailgun do
      StudentInternshipAgreement.create_from_signature_id(signature.signature_id)
      expect(Submission.find_by(student: student, code_review: code_review).meets_expectations?).to be true
    end

    it 'marks code review as passed even if submission already exists', :stub_mailgun do
      Submission.create(student: student, code_review: code_review)
      StudentInternshipAgreement.create_from_signature_id(signature.signature_id)
      expect(Submission.find_by(student: student, code_review: code_review).meets_expectations?).to be true
    end

    it 'updates the internship agreement field in close', :stub_mailgun, :dont_stub_crm do
      allow_any_instance_of(CrmLead).to receive(:update)
      student.reload
      expect_any_instance_of(CrmLead).to receive(:update).with({ "custom.#{Rails.application.config.x.crm_fields['SIGNED_INTERNSHIP_AGREEMENT']}": 'Yes' })
      StudentInternshipAgreement.create_from_signature_id(signature.signature_id)
    end
  end
end
