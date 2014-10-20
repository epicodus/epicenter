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

    # these two tests will require some extra model methods to determine the
    # if the student has submitted an assessment or not.
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

    scenario 'links to assessment show page' do
      assessment = FactoryGirl.create(:assessment_with_requirements)
      visit assessments_path
      click_link assessment.title
      expect(page).to have_content assessment.title
      expect(page).to have_content assessment.requirements.first.content
    end
  end
end

feature 'show page' do
  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:user) }
    before { sign_in student }

    context 'and submitting an assessment' do
      scenario 'with valid input' do
        assessment = FactoryGirl.create(:assessment)
        visit assessment_path(assessment)
        fill_in 'submission_link', with: 'http://github.com'
        click_button 'Submit'
        expect(page).to have_content 'Thank you for submitting'
      end

      scenario 'with invalid input' do
        assessment = FactoryGirl.create(:assessment)
        visit assessment_path(assessment)
        click_button 'Submit'
        expect(page).to have_content "can't be blank"
      end
    end

    context 'after having submitted for this assessment' do
      scenario 'allows student to resubmit' do
        assessment = FactoryGirl.create(:assessment)
        FactoryGirl.create(:submission, assessment: assessment, user: student)
        visit assessment_path(assessment)
        expect(page).to have_button 'Resubmit'
      end

      context 'and submission has been reviewed' do
        scenario 'links to submission page' do
          assessment = FactoryGirl.create(:assessment)
          submission = FactoryGirl.create(:submission, assessment: assessment, user: student)
          FactoryGirl.create(:review, submission: submission)
          visit assessment_path(assessment)
          expect(page).to have_link 'has been reviewed'
        end
      end
    end
  end
end
