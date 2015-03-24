feature 'index page' do
  let!(:assessment) { FactoryGirl.create(:assessment) }

  scenario 'not logged in' do
    visit cohort_assessments_path(assessment.cohort)
    expect(page).to have_content 'need to sign in'
  end

  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:student, cohort: assessment.cohort) }
    before { login_as(student, scope: :student) }

    scenario "but isn't this student's cohort" do
      another_cohort = FactoryGirl.create(:cohort)
      visit cohort_assessments_path(another_cohort)
      expect(page).to have_content 'not authorized'
    end

    scenario 'shows all assessments' do
      another_assessment = FactoryGirl.create(:assessment, title: 'another_assessment', cohort: assessment.cohort)
      visit cohort_assessments_path(assessment.cohort)
      expect(page).to have_content assessment.title
      expect(page).to have_content another_assessment.title
    end

    scenario 'shows if the student has submitted an assessment' do
      FactoryGirl.create(:submission, assessment: assessment, student: student)
      visit cohort_assessments_path(assessment.cohort)
      expect(page).to have_content 'Submitted'
      expect(page).to_not have_content 'Not submitted'
    end

    scenario 'shows if the assessment has been graded', :vcr do
      submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
      FactoryGirl.create(:passing_review, submission: submission)
      visit cohort_assessments_path(assessment.cohort)
      expect(page).to have_content 'Reviewed'
      expect(page).to_not have_content 'Submitted'
    end

    scenario 'links to assessment show page' do
      visit cohort_assessments_path(assessment.cohort)
      click_link assessment.title
      expect(page).to have_content assessment.title
      expect(page).to have_content assessment.requirements.first.content
    end

    scenario 'does not have button to save order of assessments' do
      visit cohort_assessments_path(assessment.cohort)
      expect(page).to_not have_button 'Save order'
    end
  end

  context 'when visiting as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:assessment) { FactoryGirl.create(:assessment) }

    before { login_as(admin, scope: :admin) }

    scenario 'has a link to create a new assessment' do
      visit cohort_assessments_path(assessment.cohort)
      click_on 'Add an assessment'
      expect(page).to have_content 'New Assessment'
    end

    scenario 'shows the number of submissions needing review for each assessment' do
      FactoryGirl.create(:submission, assessment: assessment)
      visit cohort_assessments_path(assessment.cohort)
      expect(page).to have_content '1 new submission'
    end

    scenario 'admin clicks on number of submission badge and is taken to submissions index of that assessment' do
      FactoryGirl.create(:submission, assessment: assessment)
      visit cohort_assessments_path(assessment.cohort)
      click_link '1 new submission'
      expect(page).to have_content "Submissions for #{assessment.title}"
    end

    scenario 'has a button to save order of assessments' do
      visit cohort_assessments_path(assessment.cohort)
      expect(page).to have_button 'Save order'
    end

    scenario 'changes lesson order' do
      another_assesment = FactoryGirl.create(:assessment, cohort: assessment.cohort)
      visit cohort_assessments_path(assessment.cohort)
      click_on 'Save order'
      expect(page).to have_content 'Order has been saved'
    end
  end
end

feature 'show page' do
  let(:assessment) { FactoryGirl.create(:assessment) }

  scenario 'not signed in' do
    visit assessment_path(assessment)
    expect(page).to have_content 'need to sign in'
  end

  context 'when visiting as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before do
      login_as(admin, scope: :admin)
      visit assessment_path(assessment)
    end

    scenario 'has a link to edit assessment' do
      click_on 'Edit'
      expect(page).to have_content 'Edit Assessment'
    end

    scenario 'has a link to delete assessment' do
      click_on 'Delete'
      expect(page).to have_content "#{assessment.title} has been deleted"
    end

    scenario 'has a link to create a new assessment' do
      click_on 'New'
      expect(page).to have_content 'New Assessment'
    end
  end

  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:student, cohort: assessment.cohort) }
    before { login_as(student, scope: :student) }
    subject { page }

    scenario "but this assessment is not part of your cohort" do
      assessment_of_another_cohort = FactoryGirl.create(:assessment)
      visit assessment_path(assessment_of_another_cohort)
      expect(page).to have_content 'not authorized'
    end

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

    context 'after submission has been reviewed', :vcr do
      let(:submission) { FactoryGirl.create(:submission, assessment: assessment, student: student) }
      let!(:review) { FactoryGirl.create(:passing_review, submission: submission) }

      before do
        visit assessment_path(assessment)
      end

      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to have_content review.note }
      it { is_expected.to have_content 'Meets expectations' }
    end

    context 'after resubmitting', :vcr do
      let(:submission) { FactoryGirl.create(:submission, assessment: assessment, student: student) }

      before do
        FactoryGirl.create(:passing_review, submission: submission)
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
