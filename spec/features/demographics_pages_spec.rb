feature 'Submitting demographics info' do
  let(:student) { FactoryGirl.create(:user_waiting_on_demographics, email: 'example@example.com') }

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

    scenario "can submit demographics form without filling it out" do
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end

    scenario "can submit demographics form after filling it out" do
      fill_in 'Age', with: '25'
      click_on 'Submit'
      expect(page).to have_content "Your payment methods"
    end
  end
end
