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

    # one integration test should actually test CRM full process for real, so using VCR & disabling CRM stubbing here
    scenario "can submit demographics form after filling out only required fields", :dont_stub_crm, vcr: true do
      fill_in 'demographic_info_address', with: '400 SW 6th Ave'
      fill_in 'demographic_info_city', with: 'Portland'
      fill_in 'demographic_info_state', with: 'OR'
      fill_in 'demographic_info_zip', with: '97204'
      select 'United States of America', from: 'demographic_info_country'
      fill_in 'demographic_info_birth_date', with: '01/01/2000'
      choose 'demographic_info_disability_no'
      choose 'demographic_info_veteran_no'
      select 'GED', from: 'demographic_info_education'
      choose 'demographic_info_cs_degree_no'
      select 'S', from: 'demographic_info_shirt'
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end

    scenario "can submit demographics form after filling out required and optional fields", vcr: true do
      fill_in 'demographic_info_address', with: '400 SW 6th Ave'
      fill_in 'demographic_info_city', with: 'Portland'
      fill_in 'demographic_info_state', with: 'OR'
      fill_in 'demographic_info_zip', with: '97204'
      select 'United States of America', from: 'demographic_info_country'
      fill_in 'demographic_info_birth_date', with: '01/01/2000'
      choose 'demographic_info_disability_no'
      choose 'demographic_info_veteran_no'
      select 'GED', from: 'demographic_info_education'
      choose 'demographic_info_cs_degree_no'
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

  context 'as a student with no payment due' do
    scenario "redirects to courses page if no payment due", vcr: true do
      special_plan_student = FactoryBot.create(:user_waiting_on_demographics, plan: FactoryBot.create(:special_plan))
      login_as(special_plan_student, scope: :student)
      visit root_path
      fill_in 'demographic_info_address', with: '400 SW 6th Ave'
      fill_in 'demographic_info_city', with: 'Portland'
      fill_in 'demographic_info_state', with: 'OR'
      fill_in 'demographic_info_zip', with: '97204'
      select 'United States of America', from: 'demographic_info_country'
      fill_in 'demographic_info_birth_date', with: '01/01/2000'
      choose 'demographic_info_disability_no'
      choose 'demographic_info_veteran_no'
      select 'GED', from: 'demographic_info_education'
      choose 'demographic_info_cs_degree_no'
      select 'S', from: 'demographic_info_shirt'
      click_on 'Submit'
      expect(page).to have_content "Your courses"
    end
  end
end
