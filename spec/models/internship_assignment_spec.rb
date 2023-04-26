describe InternshipAssignment do
  it { should belong_to :student }
  it { should belong_to :internship }
  it { should belong_to :course }
  it { should validate_presence_of(:student) }
  it { should validate_presence_of(:internship) }
  it { should validate_presence_of(:course) }

  it 'validates uniqueness of student scoped to course' do
    internship_assignment = FactoryBot.create(:internship_assignment)
    expect(FactoryBot.build(:internship_assignment, student: internship_assignment.student, course: internship_assignment.course)).to_not be_valid
  end

  describe '#for_internship' do
    let(:internship_assignment) { FactoryBot.create(:internship_assignment) }

    it 'returns the internship assignments for a particular internship' do
      expect(InternshipAssignment.for_internship(internship_assignment.internship)).to eq [internship_assignment]
    end
  end

  describe 'updates crm on internship assignment' do
    let(:student) { FactoryBot.create(:student) }
    let(:internship) { FactoryBot.create(:internship) }

    before { allow_any_instance_of(CrmLead).to receive(:update).and_return({}) }

    it 'updates the crm on create' do
      expect_any_instance_of(CrmLead).to receive(:update).with({ Rails.application.config.x.crm_fields['INTERNSHIP_COMPANY'] => internship.name })
      FactoryBot.create(:internship_assignment, student: student, internship: internship)
    end

    it 'updates the crm on create' do
      expect_any_instance_of(CrmLead).to receive(:update).with({ Rails.application.config.x.crm_fields['INTERNSHIP_COMPANY'] => internship.name })
      FactoryBot.create(:internship_assignment, student: student, internship: internship)
    end

    it 'updates the crm on delete' do
      ia = FactoryBot.create(:internship_assignment, student: student, internship: internship)
      expect_any_instance_of(CrmLead).to receive(:update).with({ Rails.application.config.x.crm_fields['INTERNSHIP_COMPANY'] => nil })
      ia.destroy
    end
  end
end
