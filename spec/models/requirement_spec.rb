describe Requirement do
  it { should validate_presence_of :content }
  it { should belong_to :assessment }
  it { should have_many :grades }

  describe "#latest_score_for" do
    it "returns the latest score of the student given for this requirement" do
      student = FactoryGirl.create(:student)
      assessment = FactoryGirl.create(:assessment)
      first_requirement = assessment.requirements.first
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      score = FactoryGirl.create(:score, value: 1)
      review = FactoryGirl.create(:review, submission: submission)
      FactoryGirl.create(:grade, requirement: first_requirement, score: score, review: review)
      expect(first_requirement.score_for(student)).to eq 1
    end
  end
end
