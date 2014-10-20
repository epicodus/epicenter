require 'rails_helper'

describe Assessment do
  it { should validate_presence_of :title }
  it { should validate_presence_of :section }
  it { should validate_presence_of :url }
  it { should have_many :requirements }
  it { should have_many :submissions }

  describe '#has_been_submitted_by' do
    it 'is true if the given user has already made a submission for this assessment' do
      student = FactoryGirl.create(:user)
      assessment = FactoryGirl.create(:assessment)
      FactoryGirl.create(:submission, user: student, assessment: assessment)
      expect(assessment.has_been_submitted_by(student)).to eq true
    end

    it 'is false if the given user has not made a submission for this assessment' do
      student = FactoryGirl.create(:user)
      assessment = FactoryGirl.create(:assessment)
      expect(assessment.has_been_submitted_by(student)).to eq false
    end
  end

  describe '#submission_for' do
    it 'returns submission of given user for this assessment' do
      student = FactoryGirl.create(:user)
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, user: student, assessment: assessment)
      expect(assessment.submission_for(student)).to eq submission
    end
  end
end
