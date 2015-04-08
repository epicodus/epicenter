describe Review do
  it { should belong_to :submission }
  it { should have_many :grades }
  it { should belong_to :admin }
  it { should validate_presence_of :note }
  it { should have_one(:student) }

  describe 'on creation' do
    it 'updates the submission needs review to false', :vcr do
      submission = FactoryGirl.create(:submission)
      review = FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.needs_review).to eq false
    end

    it 'emails the student' do
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      review = FactoryGirl.create(:review)
      submission = review.submission
      student = submission.student

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_REVIEW'],
          :to => student.email,
          :subject => "CodeReview reviewed",
          :text => "Hi #{student.name}. Your #{submission.code_review.title} code has been reviewed. You can view it at #{Rails.application.routes.url_helpers.code_review_url(submission.code_review)}."
        }
      )
    end
  end

  describe '#meets_expectations?', :vcr do
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
