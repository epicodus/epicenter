describe Survey do
  it { should belong_to :student }
  it { should belong_to :code_review }

  it { should validate_uniqueness_of(:student_id).scoped_to(:code_review_id) }
  it { should validate_uniqueness_of(:code_review_id).scoped_to(:student_id) }
  it { should validate_presence_of :teacher_help }
  it { should validate_presence_of :teacher_availability }
  it { should validate_presence_of :curriculum_clarity }
  it { should validate_presence_of :project_prep }
  it { should validate_presence_of :project_prompt }
end
