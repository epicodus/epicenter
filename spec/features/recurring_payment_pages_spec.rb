require 'rails_helper'

feature 'User starts recurring payments' do
  scenario 'with no upfront payment due and an account that is not recurring_active', :vcr do
    user = FactoryGirl.create(:user_with_upfront_payment)
    sign_in user
    visit payments_path
    click_on "Start recurring payments"
    expect(page).to have_content "Thank You! Your first recurring payment has been made."
  end
end
