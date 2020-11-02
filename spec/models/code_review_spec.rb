describe CodeReview do
  it { should validate_presence_of :title }
  it { should validate_presence_of :course }
  it { should have_many :objectives }
  it { should have_many :submissions }
  it { should belong_to :course }
  it { should accept_nested_attributes_for :objectives }

  it 'validates presence of at least one objective' do
    code_review = FactoryBot.build(:code_review, objectives: [])
    code_review.save
    expect(code_review.errors.full_messages.first).to eq 'Objectives must be present.'
  end

  it 'does not validate presence of objectives if github_path present' do
    allow(Github).to receive(:get_content).and_return({})
    code_review = FactoryBot.build(:code_review, objectives: [], github_path:'example.com')
    expect(code_review.save).to eq true
  end

  it 'normalizes title before saving' do
    code_review = FactoryBot.create(:code_review, title: 'test title ')
    expect(code_review.title).to eq 'test title'
  end

  it 'assigns an order number before creation (defaulted to last)' do
    code_review = FactoryBot.create(:code_review)
    next_code_review = FactoryBot.create(:code_review, course: code_review.course)
    expect(next_code_review.number).to eq 2
  end

  it 'prevents code review deletion when submissions exist' do
    code_review = FactoryBot.create(:code_review)
    FactoryBot.create(:submission, code_review: code_review)
    expect(code_review.destroy).to be false
  end

  describe 'total_points_available' do
    it 'multiplies the number of objectives by 3' do
      code_review = FactoryBot.create(:code_review, objectives: [FactoryBot.create(:objective)])
      expect(code_review.total_points_available).to eq 6
    end
  end

  describe '.default_scope' do
    let(:second_code_review) { FactoryBot.create(:code_review) }
    let(:first_code_review) { FactoryBot.create(:code_review, course: second_code_review.course) }

    it 'orders code reviews by their number, ascending' do
      first_code_review.update_attribute(:number, 1)
      second_code_review.update_attribute(:number, 2)
      expect(CodeReview.all).to eq [first_code_review, second_code_review]
    end
  end

  describe '#submission_for' do
    it 'returns submission of given user for this code_review' do
      student = FactoryBot.create(:student)
      code_review = FactoryBot.create(:code_review)
      submission = FactoryBot.create(:submission, student: student, code_review: code_review)
      expect(code_review.submission_for(student)).to eq submission
    end
  end

  describe '#exepectations_met_by?' do
    let(:code_review) { FactoryBot.create(:code_review) }
    let(:student) { FactoryBot.create(:student) }

    it "is true if the student's submission has met expectations", :stub_mailgun do
      submission = FactoryBot.create(:submission, student: student, code_review: code_review)
      FactoryBot.create(:passing_review, submission: submission)
      expect(code_review.expectations_met_by?(student)).to eq true
    end

    it "is false if the student's submission has not met expectations", :stub_mailgun do
      submission = FactoryBot.create(:submission, student: student, code_review: code_review)
      FactoryBot.create(:failing_review, submission: submission)
      expect(code_review.expectations_met_by?(student)).to eq false
    end
  end

  describe '#latest_total_score_for' do
    let(:code_review) { FactoryBot.create(:code_review) }
    let(:student) { FactoryBot.create(:student) }

    it 'gives the latest total score the student received for this code_review', :stub_mailgun do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      review = FactoryBot.create(:review, submission: submission)
      score = FactoryBot.create(:score, value: 1)
      code_review.objectives.each do |objective|
        FactoryBot.create(:grade, objective: objective, score: score, review: review)
      end
      number_of_objectives = code_review.objectives.count
      expected_score = number_of_objectives * score.value
      expect(code_review.latest_total_score_for(student)).to eq expected_score
    end

    it "gives 0 if the student hasn't submitted for this code_review" do
      expect(code_review.latest_total_score_for(student)).to eq 0
    end

    it "gives 0 if the student's submission hasn't been reviewed" do
      FactoryBot.create(:submission, code_review: code_review, student: student)
      expect(code_review.latest_total_score_for(student)).to eq 0
    end
  end

  describe '#status' do
    let(:student) { FactoryBot.create(:student) }
    let(:code_review) { FactoryBot.create(:code_review, course: student.course) }
    let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }

    it 'returns the overall student status when a student meets the requirements for a code review', :stub_mailgun do
      FactoryBot.create(:passing_review, submission: submission)
      expect(code_review.status(student)).to eq 'Met requirements'
    end

    it 'returns the overall student status when a student mostly meets the requirements for a code review', :stub_mailgun do
      FactoryBot.create(:in_between_review, submission: submission)
      expect(code_review.status(student)).to eq 'Met requirements'
    end

    it 'returns the overall student status when a student does not meet the requirements for a code review', :stub_mailgun do
      FactoryBot.create(:failing_review, submission: submission)
      expect(code_review.status(student)).to eq 'Did not meet requirements'
    end

    it 'returns the overall student status when a student did not make a submission for a code review' do
      expect(code_review.status(student)).to eq 'Pending'
    end
  end

  describe '#export_submissions' do
    it 'exports info on all submissions for this code review to students.txt file' do
      code_review = FactoryBot.create(:code_review)
      new_submission = FactoryBot.create(:submission, code_review: code_review, link: "http://new-link")
      reviewed_submission = FactoryBot.create(:submission, code_review: code_review, link: "http://reviewed-link")
      reviewed_submission.update(needs_review: false)
      filename = Rails.root.join('tmp','students.txt')
      code_review.export_submissions(filename, true)
      expect(File.read(filename)).to include new_submission.link
      expect(File.read(filename)).to include reviewed_submission.link
    end
    it 'exports info on code review submissions needing review to students.txt file' do
      code_review = FactoryBot.create(:code_review)
      new_submission = FactoryBot.create(:submission, code_review: code_review, link: "http://new-link")
      reviewed_submission = FactoryBot.create(:submission, code_review: code_review, link: "http://reviewed-link")
      reviewed_submission.update(needs_review: false)
      filename = Rails.root.join('tmp','students.txt')
      code_review.export_submissions(filename, false)
      expect(File.read(filename)).to include new_submission.link
      expect(File.read(filename)).not_to include reviewed_submission.link
    end
  end

  describe '#duplicate_code_review' do
    it 'duplicates a code review and its objectives' do
      course = FactoryBot.create(:course)
      code_review = FactoryBot.create(:code_review)
      copy_code_review = code_review.duplicate_code_review(course)
      expect(copy_code_review.save).to be true
    end

    it 'sets visible date and due date to next Friday when duplicating a full-time code review with a date' do
      course = FactoryBot.create(:course)
      code_review = FactoryBot.create(:code_review)
      travel_to Date.parse('2021-01-04') do
        copy_code_review = code_review.duplicate_code_review(course)
        expect(copy_code_review.visible_date).to eq DateTime.current.beginning_of_week + 4.days + 8.hours
        expect(copy_code_review.due_date).to eq DateTime.current.beginning_of_week + 4.days + 17.hours
      end
    end

    it 'sets visible date and due date when duplicating a part-time code review with a date' do
      course = FactoryBot.create(:part_time_course)
      code_review = FactoryBot.create(:code_review)
      travel_to Date.parse('2021-01-04') do
        copy_code_review = code_review.duplicate_code_review(course)
        expect(copy_code_review.visible_date).to eq DateTime.current.beginning_of_week + 3.days + 17.hours
        expect(copy_code_review.due_date).to eq DateTime.current.beginning_of_week + 10.days + 17.hours
      end
    end
  end

  describe '#visible?' do
    let(:student) { FactoryBot.create(:student) }
    let(:code_review) { FactoryBot.create(:code_review, course: student.course) }

    it 'returns true if code review has no visible_date', :stub_mailgun do
      code_review.visible_date = nil
      code_review.save
      expect(code_review.visible?(student)).to eq true
    end

    it 'returns false if code review expectations met', :stub_mailgun do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: submission)
      expect(code_review.visible?(student)).to eq false
    end

    it 'returns false if before class start time on code review date for full-time course' do
      travel_to code_review.visible_date.beginning_of_day do
        expect(code_review.visible?(student)).to eq false
      end
    end

    it 'returns true if on code review date at class start time for full-time course' do
      travel_to code_review.visible_date.beginning_of_day + 8.hours do
        expect(code_review.visible?(student)).to eq true
      end
    end
  end

  describe 'retrieves code review from github' do
    it 'tries to update code review from github when github_path present' do
      allow(Github).to receive(:get_content).and_return({})
      github_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md"
      expect(Github).to receive(:get_content).with(github_path)
      code_review = FactoryBot.create(:code_review, github_path: github_path)
    end

    it 'saves when code review successfully fetched from github' do
      allow(Github).to receive(:get_content).and_return({content: 'new code review content'})
      github_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md"
      code_review = FactoryBot.create(:code_review, github_path: github_path)
      expect(code_review.content).to_not eq 'test content'
    end

    it 'does not save when problem fetching code review from github' do
      allow(Github).to receive(:get_content).and_return({error: true})
      github_path = "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/master/README.md"
      code_review = FactoryBot.create(:code_review)
      code_review.github_path = github_path
      expect(code_review.save).to eq false
    end
  end
end
