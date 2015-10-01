feature 'creating a cohort' do
  scenario 'not logged in' do
    visit new_cohort_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryGirl.create(:user_with_all_documents_signed)
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
      expect(page).to have_content 'New cohort'
    end
    scenario 'with invalid input' do
      visit new_cohort_path
      click_on 'Create Cohort'
      expect(page).to have_content "can't be blank"
    end

    scenario 'from scratch' do
      visit new_cohort_path
      fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
      fill_in 'Start time', with: '9:00 AM'
      fill_in 'End time', with: '5:00 PM'
      find(:xpath, "//input[@id='cohort_class_days']").set "2015-09-06,2015-09-07,2015-09-08"
      click_on 'Create Cohort'
      expect(page).to have_content 'Class has been created'
      expect(page).to have_content 'Code Reviews'
    end

    scenario 'cloned from another cohort' do
      previous_cohort = FactoryGirl.create(:cohort, description: 'Ruby/Rails - Fall 2014')
      code_review = FactoryGirl.create(:code_review, cohort: previous_cohort)
      visit new_cohort_path
      fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
      find(:xpath, "//input[@id='cohort_class_days']").set "2015-09-06,2015-09-07,2015-09-08"
      select previous_cohort.description, from: 'Import code reviews from previous cohort'
      click_on 'Create Cohort'
      expect(page).to have_content 'Class has been created'
      expect(page).to have_content code_review.title
    end
  end
end

feature 'editing a cohort' do
  let(:cohort) { FactoryGirl.create(:cohort) }

  scenario 'not logged in' do
    visit edit_cohort_path(cohort)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryGirl.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit edit_cohort_path(cohort)
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin, current_cohort: cohort) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to cohort#edit page', js: true do
      visit root_path
      click_on "(edit)"
      expect(page).to have_content "Edit #{cohort.description}"
    end

    scenario 'with invalid input' do
      visit edit_cohort_path(cohort)
      fill_in 'Description', with: ''
      click_on 'Update Cohort'
      expect(page).to have_content "can't be blank"
    end

    scenario 'with valid input' do
      visit edit_cohort_path(cohort)
      fill_in 'Description', with: 'PHP/Drupal - Summer 2015'
      fill_in 'Start time', with: '9:00 AM'
      fill_in 'End time', with: '5:00 PM'
      find(:xpath, "//input[@id='cohort_class_days']").set "2015-09-06,2015-09-07,2015-09-08"
      click_on 'Update Cohort'
      expect(page).to have_content "PHP/Drupal - Summer 2015 has been updated"
      expect(page).to have_content 'Code Reviews'
    end
  end
end

feature 'deleting a cohort' do
  let(:cohort) { FactoryGirl.create(:cohort) }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'admin clicks delete button' do
    visit edit_cohort_path(cohort)
    click_on 'Delete'
    expect(page).to have_content "#{cohort.description} has been deleted"
  end
end
