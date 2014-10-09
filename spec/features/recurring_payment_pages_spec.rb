require 'rails_helper'

feature 'User starts recurring payments' do
  scenario 'with no upfront payment due and an account that is not recurring_active', :vcr do
    user = FactoryGirl.create(:user_with_a_payment)
    sign_in user
    visit new_recurring_payment_path
    click_on "Start recurring payments"
    expect(page).to have_content "Thank You! Your first recurring payment has been made."
  end

  scenario 'with upfront payment due', :vcr do
    user = FactoryGirl.create(:user_with_verified_bank_account)
    sign_in user
    visit new_recurring_payment_path
    expect(current_path).to eq new_upfront_payment_path
  end

  scenario 'with an account that is already recurring_active', :vcr do
    user = FactoryGirl.create(:user_with_recurring_active)
    sign_in user
    visit new_recurring_payment_path
    expect(page).to have_content "Recurring payments have already started for this account."
    expect(current_path).to eq root_path
  end
end

