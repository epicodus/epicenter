describe InternshipAssignment do
  it { should belong_to :student }
  it { should belong_to :internship }
  it { should belong_to :course }
  it { should validate_presence_of(:student) }
  it { should validate_presence_of(:internship) }
  it { should validate_presence_of(:course) }
  it { should validate_uniqueness_of(:student_id).scoped_to(:course_id) }

  describe '#for_internship' do
    let(:internship_assignment) { FactoryBot.create(:internship_assignment) }

    it 'returns the internship assignments for a particular internship' do
      expect(InternshipAssignment.for_internship(internship_assignment.internship)).to eq [internship_assignment]
    end
  end
end
