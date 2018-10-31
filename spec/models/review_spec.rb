describe Review do
  it { should belong_to :submission }
  it { should have_many :grades }
  it { should belong_to(:admin).optional }
  it { should validate_presence_of :note }
  it { should validate_presence_of :student_signature }
  it { should have_one(:student) }

  describe 'on creation' do
    it 'updates the submission needs review to false', :stub_mailgun do
      submission = FactoryBot.create(:submission)
      review = FactoryBot.create(:passing_review, submission: submission)
      expect(submission.needs_review).to eq false
    end

    it 'updates the submission review_status to pass', :stub_mailgun do
      submission = FactoryBot.create(:submission)
      review = FactoryBot.create(:passing_review, submission: submission)
      expect(submission.review_status).to eq 'pass'
    end

    it 'updates the submission review_status to fail', :stub_mailgun do
      submission = FactoryBot.create(:submission)
      review = FactoryBot.create(:failing_review, submission: submission)
      expect(submission.review_status).to eq 'fail'
    end

    it 'emails the student' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      review = FactoryBot.create(:review)
      submission = review.submission
      student = submission.student
      expect(EmailJob).to have_received(:perform_later).with({ :from => ENV['FROM_EMAIL_REVIEW'], :to => student.email, :subject => "Code review reviewed", :text => "Hi #{student.name}. Your #{submission.code_review.title} code has been reviewed. You can view it at #{Rails.application.routes.url_helpers.course_code_review_url(submission.code_review.course, submission.code_review)}." })
    end
  end

  describe '#meets_expectations?' do
    it "is true if the review's scores are all above 1", :stub_mailgun do
      review = FactoryBot.create(:passing_review)
      expect(review.meets_expectations?).to eq true
    end

    it "is false if any of the review's scores are 1", :stub_mailgun do
      review = FactoryBot.create(:failing_review)
      expect(review.meets_expectations?).to eq false
    end
  end
end
