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
end
