require 'rails_helper'

feature 'User creates a bank account' do
  before do
    user = create(:user)
    sign_in user
    visit new_bank_account_path
    fill_in 'Name on account', with: user.name
  end

  xscenario 'with valid information', js: true do
    fill_in 'Bank account number', with: '123456789'
    fill_in 'Routing number', with: '321174851'
    click_on 'Verify bank account'
    page.save_screenshot('tmp/screenshots/valid_bank_account.png')
    expect(page).to have_content 'verify the deposits'
  end

  scenario 'with missing account number', js: true do
    fill_in 'Routing number', with: '321174851'
    click_on 'Verify bank account'
    within '.alert-error' do
      expect(page).to have_content 'Missing field "account_number"'
    end
  end

  scenario 'with invalid routing number', js: true do
    fill_in 'Bank account number', with: '123456789'
    fill_in 'Routing number', with: '1234568'
    click_on 'Verify bank account'
    within '.alert-error' do
      expect(page).to have_content 'not a valid routing number'
    end
  end
end
