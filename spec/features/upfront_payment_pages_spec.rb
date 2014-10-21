require 'rails_helper'

feature 'User makes an upfront payment' do
  scenario 'when an upfront payment is due', :vcr do
    user = FactoryGirl.create(:user_with_verified_bank_account)
    sign_in user
    visit payments_path
    click_on "Make upfront payment"
    expect(page).to have_content "Thank You! Your upfront payment has been made."
  end
end
