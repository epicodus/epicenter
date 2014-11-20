describe Review do
  it { should belong_to :submission }
  it { should have_many :grades }
  it { should belong_to :admin }
  it { should validate_presence_of :note }

  describe 'on creation' do
    it 'updates the submission needs review to false' do
      submission = FactoryGirl.create(:submission)
      review = FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.needs_review).to eq false
    end
  end

  describe '#meets_expectations?' do
    it "is true if the review's scores are all above 1" do
      review = FactoryGirl.create(:passing_review)
      expect(review.meets_expectations?).to eq true
    end

    it "is false if any of the review's scores are 1" do
      review = FactoryGirl.create(:failing_review)
      expect(review.meets_expectations?).to eq false
    end
  end
end
