require 'rails_helper'

describe Submission do
  it { should validate_presence_of :link }
  it { should belong_to :assessment }
  it { should have_many :reviews }

  describe '#has_been_reviewed?' do
    it 'tells if the submission has been reviewed' do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:review, submission: submission)
      expect(submission.has_been_reviewed?).to eq true
    end
  end
end
