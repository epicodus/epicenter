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
      assessment = FactoryGirl.create(:assessment)
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
    let(:assessment) { FactoryGirl.create(:assessment) }
    before { sign_in student }
    subject { page }

    context 'before submitting' do
      before do
        visit assessment_path(assessment)
      end

      it { is_expected.to have_button 'Submit' }
      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }

    end

    context 'when submitting' do
      before do
        visit assessment_path(assessment)
      end

      scenario 'with valid input' do
        fill_in 'submission_link', with: 'http://github.com'
        click_button 'Submit'
        is_expected.to have_content 'Thank you for submitting'
      end

      scenario 'with invalid input' do
        click_button 'Submit'
        is_expected.to have_content "can't be blank"
      end
    end

    context 'after having submitted' do
      before do
        FactoryGirl.create(:submission, assessment: assessment, user: student)
        visit assessment_path(assessment)
      end

      it { is_expected.to have_button 'Resubmit' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end

    context 'after submission has been reviewed' do
      let(:submission) { FactoryGirl.create(:submission, assessment: assessment, user: student) }

      before do
        FactoryGirl.create(:review, submission: submission)
        visit assessment_path(assessment)
      end

      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to have_link 'has been reviewed' }
    end

    context 'after resubmitting' do
      let(:submission) { FactoryGirl.create(:submission, assessment: assessment, user: student) }

      before do
        FactoryGirl.create(:review, submission: submission)
        visit assessment_path(assessment)
        click_on 'Resubmit'
      end

      it { is_expected.to have_content 'Submission updated' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end
  end
end

feature 'creating an assessment' do
  scenario 'with valid input' do
    assessment = FactoryGirl.build(:assessment)
    visit new_assessment_path
    fill_in 'Title', with: assessment.title
    fill_in 'Section', with: assessment.section
    fill_in 'Url', with: assessment.url
    fill_in 'assessment_requirements_attributes_0_content', with: 'requirement'
    click_button 'Create Assessment'
    expect(page).to have_content 'Assessment has been saved'
  end

  scenario 'with invalid input' do
    assessment = FactoryGirl.build(:assessment)
    visit new_assessment_path
    click_button 'Create Assessment'
    expect(page).to have_content "can't be blank"
  end

  context 'with requirements' do
    scenario 'form defaults with 3 requirement fields' do
      visit new_assessment_path
      within('ol#requirement-fields') do
        expect(page).to have_selector('li', count: 3)
      end
    end

    scenario 'allows more requirements to be added', js: true do
      visit new_assessment_path
      click_link 'Add Requirement'
      within('ol#requirement-fields') do
        expect(page).to have_selector('li', count: 4)
      end
    end

    scenario 'requires at least one requirement to be added' do
      assessment = FactoryGirl.build(:assessment)
      visit new_assessment_path
      fill_in 'Title', with: assessment.title
      fill_in 'Section', with: assessment.section
      fill_in 'Url', with: assessment.url
      click_button 'Create Assessment'
      expect(page).to have_content 'Requirements must be present'
    end
  end
end

feature 'editing an assessment' do
  scenario 'with valid input' do
    assessment = FactoryGirl.create(:assessment)
    visit edit_assessment_path(assessment)
    fill_in 'Title', with: 'Another title'
    click_button 'Update Assessment'
    expect(page).to have_content 'Assessment updated'
  end

  scenario 'with invalid input' do
    assessment = FactoryGirl.create(:assessment)
    visit edit_assessment_path(assessment)
    fill_in 'Title', with: ''
    click_button 'Update Assessment'
    expect(page).to have_content "can't be blank"
  end

  scenario 'removing requirements', js: true do
    assessment = FactoryGirl.create(:assessment)
    requirement_count = assessment.requirements.count
    visit edit_assessment_path(assessment)
    within('ol#requirement-fields') do
      first(:link, 'x').click
    end
    click_button 'Update Assessment'
    expect(assessment.requirements.count).to eq requirement_count - 1
  end

  scenario 'adding requirements', js: true do
    assessment = FactoryGirl.create(:assessment)
    requirement_count = assessment.requirements.count
    visit edit_assessment_path(assessment)
    click_link 'Add Requirement'
    within('ol#requirement-fields') do
      all('input').last.set 'The last requirement'
    end
    click_button 'Update Assessment'
    expect(assessment.requirements.count).to eq requirement_count + 1
  end
end
