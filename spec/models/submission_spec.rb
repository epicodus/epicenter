describe Submission do
  it { should belong_to :code_review }
  it { should have_many :reviews }
  it { should belong_to :student }
  it { should belong_to(:admin).optional }

  describe "validations" do
    let(:code_review_with_optional_submissions) { FactoryBot.create(:code_review, submissions_not_required: true) }
    let(:regular_code_review) { FactoryBot.create(:code_review, submissions_not_required: false) }

    context 'if regular submission' do
      subject { FactoryBot.build(:submission, code_review: regular_code_review) }
      it { should validate_presence_of :link }
    end

    context 'if internship submission' do
      subject { FactoryBot.build(:submission, code_review: code_review_with_optional_submissions) }
      it { should_not validate_presence_of :link }
    end

    subject { FactoryBot.build(:submission) }
    it { should validate_uniqueness_of(:student_id).scoped_to(:code_review_id) }

    it 'is invalid if link is not a valid url' do
      submission = FactoryBot.build(:submission, link: 'github.com', code_review: regular_code_review)
      expect(submission.valid?).to eq false
    end

    it 'is valid if link is a valid url' do
      submission = FactoryBot.build(:submission, link: 'http://github.com', code_review: regular_code_review)
      expect(submission.valid?).to eq true
    end
  end

  describe '#previous_submissions_for_course' do
    it 'returns other submissions for the same course' do
      course = FactoryBot.create(:course)
      student = FactoryBot.create(:student, courses: [course])
      other_course = FactoryBot.create(:course)
      code_review1 = FactoryBot.create(:code_review, course: course)
      code_review2 = FactoryBot.create(:code_review, course: course)
      other_code_review = FactoryBot.create(:code_review, course: other_course)
      submission1 = FactoryBot.create(:submission, code_review: code_review1, student: student)
      submission2 = FactoryBot.create(:submission, code_review: code_review2, student: student)
      submission_for_other_code_review = FactoryBot.create(:submission, code_review: other_code_review, student: student)
      expect(submission2.other_submissions_for_course).to eq [submission1]
    end
  end

  describe 'updating the number of times submitted' do
    let(:submission) { FactoryBot.create(:submission, needs_review: true) }

    it 'updates times_submitted when a submission is first made' do
      expect(submission.times_submitted).to eq 1
    end

    it 'updates times_submitted when a submission has been updated multiple times' do
      submission.update(link: 'http://github.com')
      submission.update(link: 'http://github.com')
      expect(submission.times_submitted).to eq 3
    end

    it "doesn't update times_submitted when a review is created", :stub_mailgun do
      FactoryBot.create(:review, submission: submission)
      expect(submission.times_submitted).to eq 1
    end
   end

  describe '#needs_review?' do
    it 'is true if no review has been created for this submission' do
      submission = FactoryBot.create(:submission)
      expect(submission.needs_review?).to eq true
    end

    it 'is false if a review has been created for this submission', :stub_mailgun do
      submission = FactoryBot.create(:submission)
      FactoryBot.create(:passing_review, submission: submission)
      expect(submission.needs_review?).to eq false
    end
  end

  describe '#has_been_reviewed?', :stub_mailgun do
    it 'is true if submission has been reviewed' do
      submission = FactoryBot.create(:submission)
      FactoryBot.create(:passing_review, submission: submission)
      expect(submission.has_been_reviewed?).to eq true
    end
  end

  describe '.needing_review', :stub_mailgun do
    it 'returns only submissions still needing review' do
      reviewed_submission = FactoryBot.create(:submission)
      not_reviewed_submission = FactoryBot.create(:submission)
      FactoryBot.create(:passing_review, submission: reviewed_submission)
      expect(Submission.needing_review).to eq [not_reviewed_submission]
    end
  end

  describe '#latest_review', :stub_mailgun do
    it 'returns the latest review for this submission' do
      submission = FactoryBot.create(:submission)
      review = FactoryBot.create(:review, submission: submission)
      later_review = FactoryBot.create(:review, submission: submission)
      expect(submission.latest_review).to eq later_review
    end
  end

  describe 'default scope' do
    it 'orders by updated_at ascending' do
      first_submission = FactoryBot.create(:submission)
      second_submission = FactoryBot.create(:submission)
      first_submission.touch # updates the updated_at field to simulate resubmission
      expect(Submission.all).to eq [second_submission, first_submission]
    end
  end

  describe '#clone_or_build_review' do
    let(:submission) { FactoryBot.create(:submission) }

    it 'returns a new review object if there is no latest review' do
      expect(submission.clone_or_build_review).to be_a_new Review
    end

    it 'returns a new review object that has grades built based on number of objectives' do
      new_review = submission.clone_or_build_review
      expect(new_review.grades.size).to eq submission.code_review.objectives.size
    end

    context 'when there is a latest review', :stub_mailgun do
      let!(:old_review) { FactoryBot.create(:passing_review, submission: submission) }
      let(:new_review) { submission.clone_or_build_review }

      it "does not clone the note of the latest review" do
        expect(new_review.note).to_not eq old_review.note
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
      old_review = FactoryBot.create(:passing_review, submission: submission)
      new_review = submission.clone_or_build_review
      expect(new_review.note).to eq nil # does not clone note
      expect(new_review.submission).to eq old_review.submission
      expect(new_review.grades.first.score).to eq old_review.grades.first.score
    end
  end

  describe '#meets_expectations?', :stub_mailgun do
    let(:submission) { FactoryBot.create(:submission) }

    it 'is true if the latest review meets expectations' do
      review = FactoryBot.create(:passing_review, submission: submission)
      expect(submission.meets_expectations?).to eq true
    end

    it 'is false if the latest review does not meet expectations' do
      FactoryBot.create(:failing_review, submission: submission)
      expect(submission.meets_expectations?).to eq false
    end
  end

  describe '#for_course' do
    it 'returns submissions for a particular course' do
      course_1 = FactoryBot.create(:course)
      course_2 = FactoryBot.create(:course)
      student = FactoryBot.create(:student, courses: [course_1, course_2])
      code_review_1 = FactoryBot.create(:code_review, course: course_1)
      code_review_2 = FactoryBot.create(:code_review, course: course_2)
      submission_1 = FactoryBot.create(:submission, code_review: code_review_1)
      submission_2 = FactoryBot.create(:submission, code_review: code_review_2)
      expect(Submission.for_course(course_2)).to eq [submission_2]
    end
  end

  describe '#similar_code_reviews' do
    it 'returns other code reviews with same title' do
      course_1 = FactoryBot.create(:course)
      course_2 = FactoryBot.create(:course, language: course_1.language)
      code_review_1 = FactoryBot.create(:code_review, course: course_1)
      code_review_2 = FactoryBot.create(:code_review, course: course_2, title: code_review_1.title)
      submission = FactoryBot.create(:submission, code_review: code_review_1)
      expect(submission.similar_code_reviews).to eq [code_review_2]
    end
  end
end
