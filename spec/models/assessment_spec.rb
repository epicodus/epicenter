describe Assessment do
  it { should validate_presence_of :title }
  it { should validate_presence_of :cohort }
  it { should have_many :requirements }
  it { should have_many :submissions }
  it { should belong_to :cohort }
  it { should accept_nested_attributes_for :requirements }

  it 'validates presence of at least one requirement' do
    assessment = FactoryGirl.build(:assessment)
    assessment.save
    expect(assessment.errors.full_messages.first).to eq 'Requirements must be present.'
  end

  it 'assigns an order number before creation (defaulted to last)' do
    assessment = FactoryGirl.create(:assessment)
    next_assessment = FactoryGirl.create(:assessment, cohort: assessment.cohort)
    expect(next_assessment.number).to eq 2
  end

  describe '.default_scope' do
    let(:second_assessment) { FactoryGirl.create(:assessment) }
    let(:first_assessment) { FactoryGirl.create(:assessment, cohort: second_assessment.cohort) }

    it 'orders assessments by their number, ascending' do
      first_assessment.update_attribute(:number, 1)
      second_assessment.update_attribute(:number, 2)
      expect(Assessment.all).to eq [first_assessment, second_assessment]
    end
  end

  describe '#submission_for' do
    it 'returns submission of given user for this assessment' do
      student = FactoryGirl.create(:student)
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, student: student, assessment: assessment)
      expect(assessment.submission_for(student)).to eq submission
    end
  end

  describe '#exepectations_met_by?', :vcr do
    let(:assessment) { FactoryGirl.create(:assessment) }
    let(:student) { FactoryGirl.create(:student) }

    it "is true if the student's submission has met expectations" do
      submission = FactoryGirl.create(:submission, student: student, assessment: assessment)
      FactoryGirl.create(:passing_review, submission: submission)
      expect(assessment.expectations_met_by?(student)).to eq true
    end

    it "is false if the student's submission has not met expectations" do
      submission = FactoryGirl.create(:submission, student: student, assessment: assessment)
      FactoryGirl.create(:failing_review, submission: submission)
      expect(assessment.expectations_met_by?(student)).to eq false
    end
  end

  describe '#latest_total_score_for' do
    let(:assessment) { FactoryGirl.create(:assessment) }
    let(:student) { FactoryGirl.create(:student) }

    it 'gives the latest total score the student received for this assessment', vcr: true do
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      review = FactoryGirl.create(:review, submission: submission)
      score = FactoryGirl.create(:score, value: 1)
      assessment.requirements.each do |requirement|
        FactoryGirl.create(:grade, requirement: requirement, score: score, review: review)
      end
      number_of_requirements = assessment.requirements.count
      expected_score = number_of_requirements * score.value
      expect(assessment.latest_total_score_for(student)).to eq expected_score
    end

    it "gives 0 if the student hasn't submitted for this assessment" do
      expect(assessment.latest_total_score_for(student)).to eq 0
    end

    it "gives 0 if the student's submission hasn't been reviewed" do
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      expect(assessment.latest_total_score_for(student)).to eq 0
    end
  end
end
