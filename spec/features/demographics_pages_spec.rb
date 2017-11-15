feature 'Submitting demographics info' do
  let(:student) { FactoryBot.create(:user_waiting_on_demographics, email: 'example@example.com') }

  scenario 'as a guest cannot view form' do
    visit new_demographic_path
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    before do
      login_as(student, scope: :student)
      visit root_path
    end

    scenario "can view demographics form" do
      expect(page).to have_content "Demographics"
    end

    scenario "can not submit demographics form without filling it out", vcr: true do
      click_on 'Submit'
      expect(page).to have_content "Please correct these problems"
    end

    scenario "can submit demographics form after filling out only required fields", vcr: true do
      fill_in 'demographic_info_address', with: 'test address'
      fill_in 'demographic_info_city', with: 'test city'
      fill_in 'demographic_info_state', with: 'test state'
      fill_in 'demographic_info_zip', with: 'test zip'
      select 'United States of America', from: 'demographic_info_country'
      fill_in 'demographic_info_birth_date', with: '01/01/2000'
      choose 'demographic_info_disability_no'
      choose 'demographic_info_veteran_no'
      select 'GED', from: 'demographic_info_education'
      select 'S', from: 'demographic_info_shirt'
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end

    scenario "can submit demographics form after filling out required and optional fields", vcr: true do
      fill_in 'demographic_info_address', with: 'test address'
      fill_in 'demographic_info_city', with: 'test city'
      fill_in 'demographic_info_state', with: 'test state'
      fill_in 'demographic_info_zip', with: 'test zip'
      select 'United States of America', from: 'demographic_info_country'
      fill_in 'demographic_info_birth_date', with: '01/01/2000'
      choose 'demographic_info_disability_no'
      choose 'demographic_info_veteran_no'
      select 'GED', from: 'demographic_info_education'
      select 'S', from: 'demographic_info_shirt'
      check 'demographic_info_genders_female'
      check 'demographic_info_genders_non-binary'
      fill_in 'demographic_info_job', with: 'test job'
      fill_in 'demographic_info_salary', with: '10000'
      check 'Middle Eastern'
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end

    scenario "sees errors if enters invalid info" do
      fill_in 'demographic_info_birth_date', with: '01-01-99'
      click_on 'Submit'
      expect(page).to have_content "Please correct these problems"
    end
  end
end
