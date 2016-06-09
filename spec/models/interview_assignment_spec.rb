describe InterviewAssignment do
  it { should belong_to :student }
  it { should belong_to :internship }
  it { should validate_uniqueness_of(:internship_id).scoped_to(:student_id) }
end
