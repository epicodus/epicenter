feature 'creating a cohort' do
  scenario 'not logged in' do
    visit new_cohort_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryGirl.create(:student)
    login_as(student, scope: :student)
    visit new_cohort_path
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to cohort#new page', js: true do
      visit root_path
      click_on admin.current_cohort.description
      click_on 'Add a class'
      expect(page).to have_content 'New class'
    end
    scenario 'with invalid input' do
      visit new_cohort_path
      click_on 'Create class'
      expect(page).to have_content "can't be blank"
    end

    scenario 'from scratch' do
      visit new_cohort_path
      fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
      fill_in 'Start date', with: '2015-05-01'
      fill_in 'End date', with: '2015-09-06'
      click_on 'Create class'
      expect(page).to have_content 'Class has been created'
      expect(page).to have_content 'Assessments'
    end

    scenario 'cloned from another cohort' do
      previous_cohort = FactoryGirl.create(:cohort, description: 'Ruby/Rails - Fall 2014')
      assessment = FactoryGirl.create(:assessment, cohort: previous_cohort)
      visit new_cohort_path
      fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
      fill_in 'Start date', with: '2015-05-01'
      fill_in 'End date', with: '2015-09-06'
      select previous_cohort.description, from: 'Import assessments from previous cohort'
      click_on 'Create class'
      expect(page).to have_content 'Class has been created'
      expect(page).to have_content assessment.title
    end
  end
end
