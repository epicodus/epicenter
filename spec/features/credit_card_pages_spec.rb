feature 'Creating a credit card' do
  scenario 'as a guest' do
    visit new_credit_card_path
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    before do
      student = FactoryGirl.create(:student)
      login_as(student, scope: :student)
      visit new_credit_card_path
      fill_in 'name', with: student.name
    end

    scenario 'with valid information', :vcr, js: true do
      fill_in 'card_number', with: '4242424242424242'
      fill_in 'expiration_month', with: '12'
      fill_in 'expiration_year', with: '2016'
      fill_in 'cvc_code', with: '123'
      fill_in 'zip_code', with: '11211'
      click_on 'Add credit card'
      expect(page).to have_content 'Your credit card has been added.'
    end

    scenario 'with missing account information', js: true do
      fill_in 'card_number', with: '4012888888881881'
      fill_in 'expiration_month', with: ' '
      fill_in 'expiration_year', with: '2016'
      fill_in 'cvc_code', with: '123'
      fill_in 'zip_code', with: '11211'
      click_on 'Add credit card'
      expect(page).to have_content 'Enter a valid integer value.'
    end

    scenario 'with invalid account number', js: true do
      fill_in 'card_number', with: '4242424242424241'
      fill_in 'expiration_month', with: '12'
      fill_in 'expiration_year', with: '2016'
      fill_in 'cvc_code', with: '123'
      fill_in 'zip_code', with: '11211'
      click_on 'Add credit card'
      expect(page).to have_content 'Your card number is incorrect.'
    end

    scenario 'with a cancelled card', :vcr, js: true do
      fill_in 'card_number', with: '4222222222222220'
      fill_in 'expiration_month', with: '12'
      fill_in 'expiration_year', with: '2020'
      fill_in 'cvc_code', with: '123'
      fill_in 'zip_code', with: '11211'
      click_on 'Add credit card'
      expect(page).to have_content 'Your card was declined.'
    end
  end
end
