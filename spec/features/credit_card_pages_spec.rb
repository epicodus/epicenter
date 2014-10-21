require 'rails_helper'

feature 'User creates a credit card' do
  before do
    user = FactoryGirl.create(:user)
    sign_in user
    visit new_credit_card_path
    fill_in 'Name on card', with: user.name
  end

  xscenario 'with valid information', js: true do
    fill_in 'Card number', with: '4111111111111111'
    fill_in 'Expiration month', with: '12'
    fill_in 'Expiration year', with: '2020'
    fill_in 'CVV code', with: '123'
    fill_in 'Zip code', with: '11211'
    click_on 'Add credit card'
    expect(page).to have_content 'Your credit card has been added.'
  end

  scenario 'with missing account number', js: true do
    fill_in 'Card number', with: '4111111111111111'
    fill_in 'Expiration year', with: '2020'
    fill_in 'CVV code', with: '123'
    fill_in 'Zip code', with: '11211'
    click_on 'Add credit card'
    within '.alert-error' do
      expect(page).to have_content 'Missing field "expiration_month"'
    end
  end

  scenario 'with invalid routing number', js: true do
    fill_in 'Card number', with: '4111111111111112'
    fill_in 'Expiration month', with: '12'
    fill_in 'Expiration year', with: '2020'
    fill_in 'CVV code', with: '123'
    fill_in 'Zip code', with: '11211'
    click_on 'Add credit card'
    within '.alert-error' do
      expect(page).to have_content 'not a valid credit card number'
    end
  end
end
