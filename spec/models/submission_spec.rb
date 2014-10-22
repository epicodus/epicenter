require 'rails_helper'

describe Submission do
  it { should validate_presence_of :link }
  it { should belong_to :assessment }
  it { should have_many :reviews }

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
end
