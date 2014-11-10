feature 'index page' do
  scenario 'not logged in' do
    visit assessments_path
    expect(page).to have_content 'need to sign in'
  end

  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:student) }
    let!(:assessment) { FactoryGirl.create(:assessment) }
    before { login_as(student, scope: :student) }

    scenario 'shows all assessments' do
      another_assessment = FactoryGirl.create(:assessment, title: 'another_assessment')
      visit assessments_path
      expect(page).to have_content assessment.title
      expect(page).to have_content another_assessment.title
    end

    scenario 'shows if the student has submitted an assessment' do
      FactoryGirl.create(:submission, assessment: assessment, student: student)
      visit assessments_path
      expect(page).to have_content 'Submitted'
      expect(page).to_not have_content 'Not submitted'
    end

    scenario 'shows if the assessment has been graded' do
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      FactoryGirl.create(:review, submission: submission)
      visit assessments_path
      expect(page).to have_content 'Reviewed'
      expect(page).to_not have_content 'Submitted'
    end

    scenario 'links to assessment show page' do
      visit assessments_path
      click_link assessment.title
      expect(page).to have_content assessment.title
      expect(page).to have_content assessment.requirements.first.content
    end
  end
end

feature 'show page' do
  let(:assessment) { FactoryGirl.create(:assessment) }

  scenario 'not signed in' do
    visit assessment_path(assessment)
    expect(page).to have_content 'need to sign in'
  end

  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:student) }
    before { login_as(student, scope: :student) }
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
      before { visit assessment_path(assessment) }

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
        FactoryGirl.create(:submission, assessment: assessment, student: student)
        visit assessment_path(assessment)
      end

      it { is_expected.to have_button 'Resubmit' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end

    context 'after submission has been reviewed' do
      let(:submission) { FactoryGirl.create(:submission, assessment: assessment, student: student) }
      let!(:review) { FactoryGirl.create(:review, submission: submission) }

      before do
        visit assessment_path(assessment)
      end

      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to have_content review.note }
      it { is_expected.to have_content 'Meets expectations' }
    end

    context 'after resubmitting' do
      let(:submission) { FactoryGirl.create(:submission, assessment: assessment, student: student) }

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
  scenario 'not signed in' do
    visit new_assessment_path
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:assessment) { FactoryGirl.build(:assessment) }
    let(:admin) { FactoryGirl.create(:admin) }

    before do
      login_as(admin, scope: :admin)
      visit new_assessment_path
    end

    scenario 'with valid input' do
      fill_in 'Title', with: assessment.title
      fill_in 'Section', with: assessment.section
      fill_in 'Url', with: assessment.url
      fill_in 'assessment_requirements_attributes_0_content', with: 'requirement'
      click_button 'Create Assessment'
      expect(page).to have_content 'Assessment has been saved'
    end

    scenario 'with invalid input' do
      click_button 'Create Assessment'
      expect(page).to have_content "can't be blank"
    end

    context 'with requirements' do
      scenario 'form defaults with 3 requirement fields' do
        within('ol#requirement-fields') do
          expect(page).to have_selector('li', count: 3)
        end
      end

      scenario 'allows more requirements to be added', js: true do
        click_link 'Add Requirement'
        within('ol#requirement-fields') do
          expect(page).to have_selector('li', count: 4)
        end
      end

      scenario 'requires at least one requirement to be added' do
        fill_in 'Title', with: assessment.title
        fill_in 'Section', with: assessment.section
        fill_in 'Url', with: assessment.url
        click_button 'Create Assessment'
        expect(page).to have_content 'Requirements must be present'
      end
    end
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:student) }

    scenario 'you are not authorized' do
      login_as(student, scope: :student)
      visit new_assessment_path
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'editing an assessment' do
  let(:assessment) { FactoryGirl.create(:assessment) }

  scenario 'not signed in' do
    visit edit_assessment_path(assessment)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }

    before do
      login_as(admin, scope: :admin)
      visit edit_assessment_path(assessment)
    end

    scenario 'with valid input' do
      fill_in 'Title', with: 'Another title'
      click_button 'Update Assessment'
      expect(page).to have_content 'Assessment updated'
    end

    scenario 'with invalid input' do
      fill_in 'Title', with: ''
      click_button 'Update Assessment'
      expect(page).to have_content "can't be blank"
    end

    scenario 'removing requirements', js: true do
      requirement_count = assessment.requirements.count
      within('ol#requirement-fields') do
        first(:link, 'x').click
      end
      click_button 'Update Assessment'
      expect(assessment.requirements.count).to eq requirement_count - 1
    end

    scenario 'adding requirements', js: true do
      requirement_count = assessment.requirements.count
      click_link 'Add Requirement'
      within('ol#requirement-fields') do
        all('input').last.set 'The last requirement'
      end
      click_button 'Update Assessment'
      expect(assessment.requirements.count).to eq requirement_count + 1
    end
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:student) }

    scenario 'you are not authorized' do
      login_as(student, scope: :student)
      visit edit_assessment_path(assessment)
      expect(page).to have_content 'not authorized'
    end
  end
end
