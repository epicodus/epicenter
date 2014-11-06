require 'rails_helper'

describe 'verifying bank account', :vcr do
  context 'with correct deposit amounts' do
    before do
      login_as(student, scope: :student)
      visit payment_methods_path
      click_on 'Verify Account'
      fill_in 'First deposit amount', with: '1'
      fill_in 'Second deposit amount', with: '1'
      click_on 'Confirm account'
    end

    context 'with correct deposit amounts' do
      let(:student) { FactoryGirl.create :user_with_unverified_bank_account, plan: plan }
      let(:plan) { FactoryGirl.create :recurring_plan_with_upfront_payment }

      it 'gives the student a confirmation notice and redirects to payments page' do
        expect(page).to have_content 'account has been confirmed'
        expect(current_path).to eq payment_methods_path
      end
    end
  end

  context 'with incorrect deposit ammounts' do
    it 'gives an error notice' do
      student = FactoryGirl.create :user_with_unverified_bank_account
      login_as(student, scope: :student)
      visit payment_methods_path
      click_on 'Verify Account'
      fill_in 'First deposit amount', with: '2'
      fill_in 'Second deposit amount', with: '1'
      click_on 'Confirm account'
      expect(page).to have_content 'Authentication amounts do not match.'
    end
  end
end
