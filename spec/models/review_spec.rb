require 'rails_helper'

describe Review do
  it { should belong_to :submission }
  it { should have_many :grades }
  it { should belong_to :user }
  it { should validate_presence_of :note }

  describe 'on creation' do
    it 'updates the submission needs review to false' do
      submission = FactoryGirl.create(:submission)
      review = FactoryGirl.create(:review, submission: submission)
      expect(submission.needs_review).to eq false
    end
  end
end
