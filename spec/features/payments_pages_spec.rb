require 'rails_helper'

feature 'User views payment history' do
  scenario 'and sees the payments they have made', :vcr do
    payment = FactoryGirl.create(:payment)
    user = payment.bank_account.user
    sign_in user
    visit payments_path
    expect(page).to have_content (payment.amount / 100)
  end
end
