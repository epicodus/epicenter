describe InterviewAssignment do
  it { should belong_to :student }
  it { should belong_to :internship }
  it { should belong_to :course }
  it { should validate_presence_of(:student) }
  it { should validate_presence_of(:internship) }
  it { should validate_presence_of(:course) }
  it { should validate_uniqueness_of(:internship_id).scoped_to(:student_id) }

  describe '#order_by_internship_name' do
    let(:internship) { FactoryGirl.create(:internship, name: 'z labs') }
    let(:internship_2) { FactoryGirl.create(:internship, name: 'a labs') }
    let(:student) { FactoryGirl.create(:student) }
    let(:interview_assignment) { FactoryGirl.create(:interview_assignment, student_id: student.id, internship_id: internship.id) }
    let(:interview_assignment_2) { FactoryGirl.create(:interview_assignment, student_id: student.id, internship_id: internship_2.id) }

    it "returns a student's interview assignments ordered by internship name" do
      expect(student.interview_assignments.order_by_internship_name).to eq [interview_assignment_2, interview_assignment]
    end
  end

  describe '#for_course' do
    let(:course) { FactoryGirl.create(:course) }
    let(:interview_assignment_for_course) { FactoryGirl.create(:interview_assignment, course_id: course.id) }
    let(:interview_assignment_not_for_course) { FactoryGirl.create(:interview_assignment) }

    it 'returns the interview assignments for a particular course' do
      expect(InterviewAssignment.for_course(course)).to eq [interview_assignment_for_course]
    end
  end
end
