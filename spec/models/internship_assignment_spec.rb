describe InternshipAssignment do
  it { should belong_to :student }
  it { should belong_to :internship }
  it { should belong_to :course }
  it { should validate_presence_of(:student) }
  it { should validate_presence_of(:internship) }
  it { should validate_presence_of(:course) }
  it { should validate_uniqueness_of(:student_id).scoped_to(:course_id) }
end
