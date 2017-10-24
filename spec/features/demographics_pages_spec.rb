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

    scenario "can submit demographics form without filling it out", vcr: true do
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end

    scenario "can submit demographics form after filling it out", vcr: true do
      check 'demographic_info_genders_female'
      check 'demographic_info_genders_non-binary'
      fill_in 'demographic_info_age', with: '25'
      select 'High school diploma or equivalent', from: 'demographic_info_education'
      fill_in 'demographic_info_job', with: 'test job'
      fill_in 'demographic_info_salary', with: '10000'
      check 'Other'
      choose 'demographic_info_veteran_no'
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end

    scenario "sees errors if enters invalid info" do
      fill_in 'demographic_info_age', with: '-25'
      click_on 'Submit'
      expect(page).to have_content "Please correct these problems"
    end
  end
end
