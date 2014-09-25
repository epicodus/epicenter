require 'rails_helper'

RSpec.describe Assessment, :type => :model do
  it { should validate_presence_of :title }
  it { should validate_presence_of :section }
  it { should validate_presence_of :url }
  it { should have_many :requirements }

  describe ".graded_by_assessment" do
    it "returns a hash of the number of graded assessments" do
      assessment1 = Assessment.create(title: "first", section: "1", url: "one.com")
      assessment2 = Assessment.create(title: "second", section: "2", url: "two.com")
      requirement1a = Requirement.create(content: "req 1", assessment_id: assessment1.id)
      requirement1b = Requirement.create(content: "req 2", assessment_id: assessment1.id)
      requirement2a = Requirement.create(content: "req 1", assessment_id: assessment2.id)
      requirement2b = Requirement.create(content: "req 2", assessment_id: assessment2.id)
      submission1a = Submission.create(link: "submission.com", assessment_id: assessment1.id)
      submission1b = Submission.create(link: "submission.com", assessment_id: assessment1.id)
      submission2a = Submission.create(link: "submission.com", assessment_id: assessment2.id)
      submission2b = Submission.create(link: "submission.com", assessment_id: assessment2.id)
      grade1a1 = Grade.create(submission_id: submission1a.id, requirement_id: requirement1a.id, score: 2)
      grade1a2 = Grade.create(submission_id: submission1a.id, requirement_id: requirement1b.id, score: 3)
      grade1b1 = Grade.create(submission_id: submission1b.id, requirement_id: requirement1a.id, score: 1)
      grade2a1 = Grade.create(submission_id: submission2a.id, requirement_id: requirement2a.id, score: 1)
      result = {"first" => 2, "second" => 1}
      expect(Assessment.graded_by_assessment).to eq result
    end
  end
end
