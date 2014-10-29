require 'rails_helper'

feature 'index page' do
  let(:assessment) { FactoryGirl.create(:assessment) }
  let(:student) { FactoryGirl.create(:user) }

  scenario 'lists submissions' do
    submission = FactoryGirl.create(:submission, assessment: assessment, user: student)
    visit assessment_submissions_path(assessment)
    expect(page).to have_content submission.user.name
  end

  scenario 'lists only submissions needing review' do
    reviewed_submission = FactoryGirl.create(:submission, assessment: assessment, user: student)
    FactoryGirl.create(:review, submission: reviewed_submission)
    visit assessment_submissions_path(assessment)
    expect(page).to_not have_content reviewed_submission.user.name
  end

  scenario 'lists submissions in order of when they were submitted' do
    another_student = FactoryGirl.create(:user)
    first_submission = FactoryGirl.create(:submission, assessment: assessment, user: student)
    second_submission = FactoryGirl.create(:submission, assessment: assessment, user: another_student)
    first_submission.touch # updates the updated_at field to simulate resubmission
    visit assessment_submissions_path(assessment)
    expect(first('.submission')).to have_content second_submission.user.name
  end

  context 'within an individual submission' do
    include ActiveSupport::Testing::TimeHelpers

    scenario 'shows how long ago the submission was last updated' do
      travel_to 2.days.ago do
        FactoryGirl.create(:submission, assessment: assessment, user: student)
      end
      visit assessment_submissions_path(assessment)
      expect(page).to have_content '2 days ago'
    end

    scenario 'clicking review link to show review form', js: true do
      FactoryGirl.create(:submission, assessment: assessment, user: student)
      visit assessment_submissions_path(assessment)
      expect(page).to_not have_button 'Create Review'
      click_on 'Review'
      expect(page).to have_content assessment.requirements.first.content
      expect(page).to have_button 'Create Review'
    end

    context 'creating a review', js: true do
      let(:teacher) { FactoryGirl.create(:user) }
      before do
        (1..4).each { |n| Score.create(value: n, description: "description #{n}") }
      end

      scenario 'with valid input' do
        FactoryGirl.create(:submission, assessment: assessment, user: student)
        sign_in teacher
        visit assessment_submissions_path(assessment)
        click_on 'Review'
        fill_in 'Note', with: 'Well done!'
        click_on 'Create Review'
        expect(page).to have_content 'Saved!'
      end

      scenario 'with invalid input' do
        FactoryGirl.create(:submission, assessment: assessment, user: student)
        sign_in teacher
        visit assessment_submissions_path(assessment)
        click_on 'Review'
        click_on 'Create Review'
        expect(page).to have_content "can't be blank"
      end
    end
  end
end
