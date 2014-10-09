require 'rails_helper'

feature 'User makes an upfront payment' do
  scenario 'when an upfront payment is due', :vcr do
    user = FactoryGirl.create(:user_with_verified_bank_account)
    sign_in user
    visit new_upfront_payment_path
    click_on "Make upfront payment"
    expect(page).to have_content "Thank You! Your upfront payment has been made."
  end

  scenario 'when no upfront payment is due', :vcr do
    user = FactoryGirl.create(:user_with_a_payment)
    sign_in user
    visit new_upfront_payment_path
    expect(page).to have_content "There are no upfront payments due on this account."
    expect(current_path).to eq root_path
  end
end

