describe Requirement do
  it { should validate_presence_of :content }
  it { should belong_to :assessment }
  it { should have_many :grades }

  describe "#score_for" do
    it "returns the latest score of the student given for this requirement", vcr: true do
      student = FactoryGirl.create(:student)
      assessment = FactoryGirl.create(:assessment)
      first_requirement = assessment.requirements.first
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      score = FactoryGirl.create(:score, value: 1)
      review = FactoryGirl.create(:review, submission: submission)
      FactoryGirl.create(:grade, requirement: first_requirement, score: score, review: review)
      expect(first_requirement.score_for(student)).to eq 1
    end

    it "returns 0 if the student hasn't submitted for the requirement's assessment" do
      student = FactoryGirl.create(:student)
      assessment = FactoryGirl.create(:assessment)
      first_requirement = assessment.requirements.first
      expect(first_requirement.score_for(student)).to eq 0
    end

    it "returns 0 if the student's submission hasn't been reviewed" do
      student = FactoryGirl.create(:student)
      assessment = FactoryGirl.create(:assessment)
      first_requirement = assessment.requirements.first
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      expect(first_requirement.score_for(student)).to eq 0
    end
  end
end
