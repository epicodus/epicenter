describe Submission do
  it { should validate_presence_of :link }
  it { should belong_to :assessment }
  it { should have_many :reviews }
  it { should belong_to :student }
  it { should validate_uniqueness_of(:student_id).scoped_to(:assessment_id) }

  describe '#needs_review?' do
    it 'is true if no review has been created for this submission' do
      submission = FactoryGirl.create(:submission)
      expect(submission.needs_review?).to eq true
    end

    it 'is false if a review has been created for this submission' do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.needs_review?).to eq false
    end
  end

  describe '#has_been_reviewed?' do
    it 'is true if submission has been reviewed' do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.has_been_reviewed?).to eq true
    end
  end

  describe '.needing_review' do
    it 'returns only submissions still needing review' do
      reviewed_submission = FactoryGirl.create(:submission)
      not_reviewed_submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:passing_review, submission: reviewed_submission)
      expect(Submission.needing_review).to eq [not_reviewed_submission]
    end
  end

  describe '#latest_review' do
    it 'returns the latest review for this submission' do
      submission = FactoryGirl.create(:submission)
      review = FactoryGirl.create(:review, submission: submission)
      later_review = FactoryGirl.create(:review, submission: submission)
      expect(submission.latest_review).to eq later_review
    end
  end

  describe 'default scope' do
    it 'orders by updated_at ascending' do
      first_submission = FactoryGirl.create(:submission)
      second_submission = FactoryGirl.create(:submission)
      first_submission.touch # updates the updated_at field to simulate resubmission
      expect(Submission.all).to eq [second_submission, first_submission]
    end
  end

  describe 'latest_review' do
    it 'returns the most recent review for this submissions' do
      submission = FactoryGirl.create(:submission)
      first_review = FactoryGirl.create(:passing_review, submission: submission)
      second_review = FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.latest_review).to eq second_review
    end
  end

  describe '#clone_or_build_review' do
    let(:submission) { FactoryGirl.create(:submission) }

    it 'returns a new review object if there is no latest review' do
      expect(submission.clone_or_build_review).to be_a_new Review
    end

    it 'returns a new review object that has grades built based on number of requirements' do
      new_review = submission.clone_or_build_review
      expect(new_review.grades.size).to eq submission.assessment.requirements.size
    end

    it 'returns a cloned review object if there is a latest review' do
      old_review = FactoryGirl.create(:passing_review, submission: submission)
      new_review = submission.clone_or_build_review
      expect(new_review.note).to eq old_review.note
      expect(new_review.submission).to eq old_review.submission
      expect(new_review.grades.first.score).to eq old_review.grades.first.score
    end
  end

  describe '#meets_expectations?' do
    let(:submission) { FactoryGirl.create(:submission) }

    it 'is true if the latest review meets expectations' do
      review = FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.meets_expectations?).to eq true
    end

    it 'is false if the latest review does not meet expectations' do
      FactoryGirl.create(:failing_review, submission: submission)
      expect(submission.meets_expectations?).to eq false
    end
  end
end
