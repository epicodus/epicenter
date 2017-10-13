describe CodeReview do
  it { should validate_presence_of :title }
  it { should validate_presence_of :course }
  it { should have_many :objectives }
  it { should have_many :submissions }
  it { should belong_to :course }
  it { should accept_nested_attributes_for :objectives }

  it 'duplicates a code review and its objectives' do
    course = FactoryGirl.create(:course)
    code_review = FactoryGirl.create(:code_review)
    copy_code_review = code_review.duplicate_code_review(course)
    expect(copy_code_review.save).to be true
  end

  it 'sets date to next Friday when duplicating a code review with a date' do
    course = FactoryGirl.create(:course)
    code_review = FactoryGirl.create(:code_review)
    copy_code_review = code_review.duplicate_code_review(course)
    expect(copy_code_review.date).to eq Date.today.beginning_of_week + 4.days
  end

  it 'validates presence of at least one objective' do
    code_review = FactoryGirl.build(:code_review)
    code_review.save
    expect(code_review.errors.full_messages.first).to eq 'Objectives must be present.'
  end

  it 'assigns an order number before creation (defaulted to last)' do
    code_review = FactoryGirl.create(:code_review)
    next_code_review = FactoryGirl.create(:code_review, course: code_review.course)
    expect(next_code_review.number).to eq 2
  end

  it 'prevents code review deletion when submissions exist' do
    code_review = FactoryGirl.create(:code_review)
    FactoryGirl.create(:submission, code_review: code_review)
    expect(code_review.destroy).to be false
  end

  describe 'total_points_available' do
    it 'multiplies the number of objectives by 3' do
      code_review = FactoryGirl.create(:code_review, objectives: [FactoryGirl.create(:objective)])
      expect(code_review.total_points_available).to eq 6
    end
  end

  describe '.default_scope' do
    let(:second_code_review) { FactoryGirl.create(:code_review) }
    let(:first_code_review) { FactoryGirl.create(:code_review, course: second_code_review.course) }

    it 'orders code reviews by their number, ascending' do
      first_code_review.update_attribute(:number, 1)
      second_code_review.update_attribute(:number, 2)
      expect(CodeReview.all).to eq [first_code_review, second_code_review]
    end
  end

  describe '#submission_for' do
    it 'returns submission of given user for this code_review' do
      student = FactoryGirl.create(:student)
      code_review = FactoryGirl.create(:code_review)
      submission = FactoryGirl.create(:submission, student: student, code_review: code_review)
      expect(code_review.submission_for(student)).to eq submission
    end
  end

  describe '#exepectations_met_by?' do
    let(:code_review) { FactoryGirl.create(:code_review) }
    let(:student) { FactoryGirl.create(:student) }

    it "is true if the student's submission has met expectations", :stub_mailgun do
      submission = FactoryGirl.create(:submission, student: student, code_review: code_review)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(code_review.expectations_met_by?(student)).to eq true
    end

    it "is false if the student's submission has not met expectations", :stub_mailgun do
      submission = FactoryGirl.create(:submission, student: student, code_review: code_review)
      FactoryGirl.create(:failing_review, submission: submission)
      expect(code_review.expectations_met_by?(student)).to eq false
    end
  end

  describe '#latest_total_score_for' do
    let(:code_review) { FactoryGirl.create(:code_review) }
    let(:student) { FactoryGirl.create(:student) }

    it 'gives the latest total score the student received for this code_review', :stub_mailgun do
      submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
      review = FactoryGirl.create(:review, submission: submission)
      score = FactoryGirl.create(:score, value: 1)
      code_review.objectives.each do |objective|
        FactoryGirl.create(:grade, objective: objective, score: score, review: review)
      end
      number_of_objectives = code_review.objectives.count
      expected_score = number_of_objectives * score.value
      expect(code_review.latest_total_score_for(student)).to eq expected_score
    end

    it "gives 0 if the student hasn't submitted for this code_review" do
      expect(code_review.latest_total_score_for(student)).to eq 0
    end

    it "gives 0 if the student's submission hasn't been reviewed" do
      FactoryGirl.create(:submission, code_review: code_review, student: student)
      expect(code_review.latest_total_score_for(student)).to eq 0
    end
  end

  describe '#status' do
    let(:student) { FactoryGirl.create(:student) }
    let(:code_review) { FactoryGirl.create(:code_review, course: student.course) }
    let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }

    it 'returns the overall student status when a student meets the requirements for a code review', :stub_mailgun do
      FactoryGirl.create(:passing_review, submission: submission)
      expect(code_review.status(student)).to eq 'Met requirements'
    end

    it 'returns the overall student status when a student mostly meets the requirements for a code review', :stub_mailgun do
      FactoryGirl.create(:in_between_review, submission: submission)
      expect(code_review.status(student)).to eq 'Met requirements'
    end

    it 'returns the overall student status when a student does not meet the requirements for a code review', :stub_mailgun do
      FactoryGirl.create(:failing_review, submission: submission)
      expect(code_review.status(student)).to eq 'Did not meet requirements'
    end

    it 'returns the overall student status when a student did not make a submission for a code review' do
      expect(code_review.status(student)).to eq 'Pending'
    end
  end

  describe '#export_submissions' do
    it 'exports info on all submissions for this code review to students.txt file' do
      code_review = FactoryGirl.create(:code_review)
      new_submission = FactoryGirl.create(:submission, code_review: code_review, link: "http://new-link")
      reviewed_submission = FactoryGirl.create(:submission, code_review: code_review, link: "http://reviewed-link")
      reviewed_submission.update(needs_review: false)
      filename = Rails.root.join('tmp','students.txt')
      code_review.export_submissions(filename, true)
      expect(File.read(filename)).to include new_submission.link
      expect(File.read(filename)).to include reviewed_submission.link
    end
    it 'exports info on code review submissions needing review to students.txt file' do
      code_review = FactoryGirl.create(:code_review)
      new_submission = FactoryGirl.create(:submission, code_review: code_review, link: "http://new-link")
      reviewed_submission = FactoryGirl.create(:submission, code_review: code_review, link: "http://reviewed-link")
      reviewed_submission.update(needs_review: false)
      filename = Rails.root.join('tmp','students.txt')
      code_review.export_submissions(filename, false)
      expect(File.read(filename)).to include new_submission.link
      expect(File.read(filename)).not_to include reviewed_submission.link
    end
  end

  describe '#visible?' do
    let(:student) { FactoryGirl.create(:student) }
    let(:code_review) { FactoryGirl.create(:code_review, course: student.course) }

    it 'returns true if code review has no date', :stub_mailgun do
      code_review.date = nil
      code_review.save
      expect(code_review.visible?(student)).to eq true
    end

    it 'returns false if code review expectations met', :stub_mailgun do
      submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(code_review.visible?(student)).to eq false
    end

    it 'returns false if before class start time on code review date for full-time course' do
      travel_to code_review.date do
        expect(code_review.visible?(student)).to eq false
      end
    end

    it 'returns true if on code review date at class start time for full-time course' do
      travel_to code_review.date.in_time_zone(student.course.office.time_zone) + 8.hours do
        expect(code_review.visible?(student)).to eq true
      end
    end

    it 'returns true if on day before code review date for part-time course' do
      part_time_course = FactoryGirl.create(:part_time_course)
      part_time_student = FactoryGirl.create(:student, courses: [part_time_course])
      part_time_code_review = FactoryGirl.create(:code_review, course: part_time_course)
      travel_to code_review.date - 1.day do
        expect(part_time_code_review.visible?(student)).to eq true
      end
    end
  end
end
