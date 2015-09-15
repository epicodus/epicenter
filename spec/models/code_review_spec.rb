describe CodeReview do
  it { should validate_presence_of :title }
  it { should validate_presence_of :cohort }
  it { should have_many :objectives }
  it { should have_many :submissions }
  it { should belong_to :cohort }
  it { should accept_nested_attributes_for :objectives }

  it 'duplicates a code review and its objectives' do
    cohort = FactoryGirl.create(:cohort)
    code_review = FactoryGirl.create(:code_review)
    copy_code_review = code_review.duplicate_code_review_and_objectives(cohort)
    expect(copy_code_review.save).to be true
  end

  it 'validates presence of at least one objective' do
    code_review = FactoryGirl.build(:code_review)
    code_review.save
    expect(code_review.errors.full_messages.first).to eq 'Objectives must be present.'
  end

  it 'assigns an order number before creation (defaulted to last)' do
    code_review = FactoryGirl.create(:code_review)
    next_code_review = FactoryGirl.create(:code_review, cohort: code_review.cohort)
    expect(next_code_review.number).to eq 2
  end

  describe '.default_scope' do
    let(:second_code_review) { FactoryGirl.create(:code_review) }
    let(:first_code_review) { FactoryGirl.create(:code_review, cohort: second_code_review.cohort) }

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

  describe '#exepectations_met_by?', :vcr do
    let(:code_review) { FactoryGirl.create(:code_review) }
    let(:student) { FactoryGirl.create(:student) }

    it "is true if the student's submission has met expectations" do
      submission = FactoryGirl.create(:submission, student: student, code_review: code_review)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(code_review.expectations_met_by?(student)).to eq true
    end

    it "is false if the student's submission has not met expectations" do
      submission = FactoryGirl.create(:submission, student: student, code_review: code_review)
      FactoryGirl.create(:failing_review, submission: submission)
      expect(code_review.expectations_met_by?(student)).to eq false
    end
  end

  describe '#latest_total_score_for' do
    let(:code_review) { FactoryGirl.create(:code_review) }
    let(:student) { FactoryGirl.create(:student) }

    it 'gives the latest total score the student received for this code_review', vcr: true do
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
      submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
      expect(code_review.latest_total_score_for(student)).to eq 0
    end
  end
end
