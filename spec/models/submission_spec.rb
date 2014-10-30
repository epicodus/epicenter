require 'rails_helper'

describe Submission do
  it { should validate_presence_of :link }
  it { should belong_to :assessment }
  it { should have_many :reviews }
  it { should have_one :latest_review }
  it { should validate_uniqueness_of(:user_id).scoped_to(:assessment_id) }

  describe '#needs_review?' do
    it 'is true if no review has been created for this submission' do
      submission = FactoryGirl.create(:submission)
      expect(submission.needs_review?).to eq true
    end

    it 'is false if a review has been created for this submission' do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:review, submission: submission)
      expect(submission.needs_review?).to eq false
    end
  end

  describe '#has_been_reviewed?' do
    it 'is true if submission has been reviewed' do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:review, submission: submission)
      expect(submission.has_been_reviewed?).to eq true
    end
  end

  describe '.needing_review' do
    it 'returns only submissions still needing review' do
      reviewed_submission = FactoryGirl.create(:submission)
      not_reviewed_submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:review, submission: reviewed_submission)
      expect(Submission.needing_review).to eq [not_reviewed_submission]
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
      first_review = FactoryGirl.create(:review, submission: submission)
      second_review = FactoryGirl.create(:review, submission: submission)
      expect(submission.latest_review).to eq second_review
    end
  end
end
