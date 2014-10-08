require 'rails_helper'

feature 'User starts recurring payments' do
  scenario 'and sees a confirmation message', :vcr do
    user = FactoryGirl.create(:user_with_verified_bank_account)
    sign_in user
    visit new_recurring_payment_path
    click_on "Start recurring payments"
    expect(page).to have_content "Thank You! Your first recurring payment has been made."
  end
end

