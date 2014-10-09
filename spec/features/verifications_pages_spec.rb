require 'rails_helper'

describe 'verifying bank account', vcr: true do
  let(:user) { FactoryGirl.create :user_with_unverified_bank_account }

  before do
    sign_in(user)
  end

  context 'with correct deposit amounts and upfront payment due' do
    it 'gives the user a confirmation notice and redirects to make upfront payment' do
      correctly_verify_bank_account(user)
      expect(page).to have_content 'account has been confirmed'
      expect(current_path).to eq new_upfront_payment_path
    end
  end

  context 'with correct deposit amounts and no upfront payment due' do
    it 'gives the user a confirmation notice and redirects to start recurring payments' do
      user.plan.update(upfront_amount: 0)
      correctly_verify_bank_account(user)
      expect(page).to have_content 'account has been confirmed'
      expect(current_path).to eq new_recurring_payment_path
    end
  end

  context 'with incorrect deposit ammounts' do
    it 'gives an error notice' do
      fill_in 'First deposit amount', with: '2'
      fill_in 'Second deposit amount', with: '1'
      click_on 'Confirm account & start payments'
      expect(page).to have_content 'Authentication amounts do not match.'
    end
  end
end
