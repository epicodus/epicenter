describe Submission do
  it { should belong_to :code_review }
  it { should have_many :reviews }
  it { should belong_to :student }

  describe "validations" do
    context 'if regular submission' do
      course = FactoryGirl.create(:course, internship_course: false)
      code_review = FactoryGirl.create(:code_review, course: course)
      subject { FactoryGirl.build(:submission, code_review: code_review) }
      it { should validate_presence_of :link }
    end

    context 'if regular submission' do
      internship_course = FactoryGirl.create(:course, internship_course: true)
      code_review = FactoryGirl.create(:code_review, course: internship_course)
      subject { FactoryGirl.build(:submission, code_review: code_review) }
      it { should_not validate_presence_of :link }
    end

    subject { FactoryGirl.build(:submission) }
    it { should validate_uniqueness_of(:student_id).scoped_to(:code_review_id) }

    it 'is invalid if link is not a valid url' do
      course = FactoryGirl.create(:course, internship_course: false)
      code_review = FactoryGirl.create(:code_review, course: course)
      submission = FactoryGirl.build(:submission, link: 'github.com', code_review: code_review)
      expect(submission.valid?).to eq false
    end

    it 'is valid if link is a valid url' do
      course = FactoryGirl.create(:course, internship_course: false)
      code_review = FactoryGirl.create(:code_review, course: course)
      submission = FactoryGirl.build(:submission, link: 'http://github.com', code_review: code_review)
      expect(submission.valid?).to eq true
    end
  end

  describe '#needs_review?' do
    it 'is true if no review has been created for this submission' do
      submission = FactoryGirl.create(:submission)
      expect(submission.needs_review?).to eq true
    end

    it 'is false if a review has been created for this submission', :stub_mailgun do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.needs_review?).to eq false
    end
  end

  describe '#has_been_reviewed?', :stub_mailgun do
    it 'is true if submission has been reviewed' do
      submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(submission.has_been_reviewed?).to eq true
    end
  end

  describe '.needing_review', :stub_mailgun do
    it 'returns only submissions still needing review' do
      reviewed_submission = FactoryGirl.create(:submission)
      not_reviewed_submission = FactoryGirl.create(:submission)
      FactoryGirl.create(:passing_review, submission: reviewed_submission)
      expect(Submission.needing_review).to eq [not_reviewed_submission]
    end
  end

  describe '#latest_review', :stub_mailgun do
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

  describe '#clone_or_build_review' do
    let(:submission) { FactoryGirl.create(:submission) }

    it 'returns a new review object if there is no latest review' do
      expect(submission.clone_or_build_review).to be_a_new Review
    end

    it 'returns a new review object that has grades built based on number of objectives' do
      new_review = submission.clone_or_build_review
      expect(new_review.grades.size).to eq submission.code_review.objectives.size
    end

    context 'when there is a latest review', :stub_mailgun do
      let!(:old_review) { FactoryGirl.create(:passing_review, submission: submission) }
      let(:new_review) { submission.clone_or_build_review }

      it "clones the note of the latest review" do
        expect(new_review.note).to eq old_review.note
      end

      it "clones the submission_id of the latest review" do
        expect(new_review.submission).to eq old_review.submission
      end

      it "clones the grades of the latest review" do
        new_review_grade_scores = new_review.grades.map { |grade| grade.score }
        old_review_grade_scores = old_review.grades.map { |grade| grade.score }
        expect(new_review_grade_scores).to eq old_review_grade_scores
      end
    end

    it 'returns a cloned review object if there is a latest review', :stub_mailgun do
      old_review = FactoryGirl.create(:passing_review, submission: submission)
      new_review = submission.clone_or_build_review
      expect(new_review.note).to eq old_review.note
      expect(new_review.submission).to eq old_review.submission
      expect(new_review.grades.first.score).to eq old_review.grades.first.score
    end
  end

  describe '#meets_expectations?', :stub_mailgun do
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

  describe '#for_course' do
    it 'returns submissions for a particular course' do
      course_1 = FactoryGirl.create(:course)
      course_2 = FactoryGirl.create(:course)
      student = FactoryGirl.create(:student, courses: [course_1, course_2])
      code_review_1 = FactoryGirl.create(:code_review, course: course_1)
      code_review_2 = FactoryGirl.create(:code_review, course: course_2)
      submission_1 = FactoryGirl.create(:submission, code_review: code_review_1)
      submission_2 = FactoryGirl.create(:submission, code_review: code_review_2)
      expect(Submission.for_course(course_2)).to eq [submission_2]
    end
  end
end
