describe Objective do
  it { should validate_presence_of :content }
  it { should belong_to :code_review }
  it { should have_many :grades }

  describe "#score_for" do
    it "returns the latest score of the student given for this objective", :stub_mailgun do
      student = FactoryBot.create(:student)
      code_review = FactoryBot.create(:code_review)
      first_objective = code_review.objectives.first
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      score = FactoryBot.create(:score, value: 1)
      review = FactoryBot.create(:review, submission: submission)
      FactoryBot.create(:grade, objective: first_objective, score: score, review: review)
      expect(first_objective.score_for(student)).to eq 1
    end

    it "returns 0 if the student hasn't submitted for the objective's code_review" do
      student = FactoryBot.create(:student)
      code_review = FactoryBot.create(:code_review)
      first_objective = code_review.objectives.first
      expect(first_objective.score_for(student)).to eq 0
    end

    it "returns 0 if the student's submission hasn't been reviewed" do
      student = FactoryBot.create(:student)
      code_review = FactoryBot.create(:code_review)
      first_objective = code_review.objectives.first
      FactoryBot.create(:submission, code_review: code_review, student: student)
      expect(first_objective.score_for(student)).to eq 0
    end
  end
end
