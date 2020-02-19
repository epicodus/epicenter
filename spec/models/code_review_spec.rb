describe CodeReview do
  it { should validate_presence_of :title }
  it { should validate_presence_of :course }
  it { should have_many :objectives }
  it { should have_many :submissions }
  it { should belong_to :course }
  it { should accept_nested_attributes_for :objectives }

  it 'duplicates a code review and its objectives' do
    course = FactoryBot.create(:course)
    code_review = FactoryBot.create(:code_review)
    copy_code_review = code_review.duplicate_code_review(course)
    expect(copy_code_review.save).to be true
  end

  it 'sets date to next Friday when duplicating a code review with a date' do
    course = FactoryBot.create(:course)
    code_review = FactoryBot.create(:code_review)
    copy_code_review = code_review.duplicate_code_review(course)
    expect(copy_code_review.date).to eq Date.today.beginning_of_week + 4.days
  end

  it 'validates presence of at least one objective' do
    code_review = FactoryBot.build(:code_review)
    code_review.save
    expect(code_review.errors.full_messages.first).to eq 'Objectives must be present.'
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

  describe '#visible?' do
    let(:student) { FactoryBot.create(:student) }
    let(:code_review) { FactoryBot.create(:code_review, course: student.course) }

    it 'returns true if code review has no date', :stub_mailgun do
      code_review.date = nil
      code_review.save
      expect(code_review.visible?(student)).to eq true
    end

    it 'returns false if code review expectations met', :stub_mailgun do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: submission)
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

    it 'returns true if 2 days before code review date for part-time course' do
      part_time_course = FactoryBot.create(:part_time_course)
      student = FactoryBot.create(:student, courses: [part_time_course])
      part_time_code_review = FactoryBot.create(:code_review, course: part_time_course)
      travel_to part_time_code_review.date - 2.days do
        expect(part_time_code_review.visible?(student)).to eq true
      end
    end

    it 'returns true if on day before code review date for part-time track course' do
      js_part_time_js_react_course = FactoryBot.create(:part_time_course)
      student = FactoryBot.create(:student, courses: [js_part_time_js_react_course])
      part_time_js_react_code_review = FactoryBot.create(:code_review, course: js_part_time_js_react_course)
      travel_to part_time_js_react_code_review.date - 2.days do
        expect(part_time_js_react_code_review.visible?(student)).to eq true
      end
    end
  end

  describe 'before_save_survey' do
    it 'saves survey URL correctly when full code pasted in from surveymonkey' do
      input = '<script>(function(t,e,s,n){var o,a,c;t.SMCX=t.SMCX||[],e.getElementById(n)||(o=e.getElementsByTagName(s),a=o[o.length-1],c=e.createElement(s),c.type="text/javascript",c.async=!0,c.id=n,c.src=["https:"===location.protocol?"https://":"http://","widget.surveymonkey.com/collect/website/js/tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js"].join(""),a.parentNode.insertBefore(c,a))})(window,document,"script","smcx-sdk");</script><a style="font: 12px Helvetica, sans-serif; color: #999; text-decoration: none;" href=https://www.surveymonkey.com> Create your own user feedback survey </a>'
      code_review = FactoryBot.create(:code_review, survey: input)
      expect(code_review.survey).to eq 'tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js'
    end

    it 'saves survey URL correctly when already previously saved' do
      input = '<script>(function(t,e,s,n){var o,a,c;t.SMCX=t.SMCX||[],e.getElementById(n)||(o=e.getElementsByTagName(s),a=o[o.length-1],c=e.createElement(s),c.type="text/javascript",c.async=!0,c.id=n,c.src=["https:"===location.protocol?"https://":"http://","widget.surveymonkey.com/collect/website/js/tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js"].join(""),a.parentNode.insertBefore(c,a))})(window,document,"script","smcx-sdk");</script><a style="font: 12px Helvetica, sans-serif; color: #999; text-decoration: none;" href=https://www.surveymonkey.com> Create your own user feedback survey </a>'
      code_review = FactoryBot.create(:code_review, survey: input)
      code_review.save
      expect(code_review.survey).to eq 'tRaiETqnLgj758hTBazgd4JtpE_2BzvN0y_2F5yj2I6l3GecJTVxOlGlsNUZGz_2F9oNyq.js'
    end

    it 'saves survey URL as nil when does not include .js' do
      input = 'bad code'
      code_review = FactoryBot.create(:code_review, survey: input)
      expect(code_review.survey).to eq nil
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
