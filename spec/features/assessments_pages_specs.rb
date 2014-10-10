require 'rails_helper'

feature 'index page' do
  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:user) }
    before { sign_in student }

    scenario 'shows all assessments' do
      first_assessment = FactoryGirl.create(:assessment)
      second_assessment = FactoryGirl.create(:assessment, title: 'another_assessment')
      visit assessments_path
      expect(page).to have_content first_assessment.title
      expect(page).to have_content second_assessment.title
    end

    xscenario 'shows if the student has submitted an assessment' do
      assessment = FactoryGirl.create(:assessment)
      FactoryGirl.create(:submission, assessment: assessment, user: student)
      visit assessments_path
      expect(page).to have_content 'Submitted'
      expect(page).to_not have_content 'Not submitted'
    end

    xscenario 'shows if the assessment has been graded' do
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, assessment: assessment, user: student)
      FactoryGirl.create(:review, submission: submission)
      visit assessments_path
      expect(page).to have_content 'Graded'
      expect(page).to_not have_content 'Submitted'
    end
  end
end
