require 'rails_helper'

feature 'User views payment index page' do
  context 'before any payments have been made', :vcr do
    it "doesn't show payment history" do
      user = FactoryGirl.create(:user_with_credit_card)
      sign_in user
      visit payments_path
      expect(page).to have_content "Looks like you haven't made any payments yet."
    end
  end

  context 'after a payment has been made with bank account', :vcr do
    it 'shows payment history with correct charge' do
      payment = FactoryGirl.create(:payment, amount: 600_00)
      user = payment.user
      sign_in user
      visit payments_path
      expect(page).to have_content 600.00
    end
  end

  context 'after a payment has been made with credit card', :vcr do
    it 'shows payment history with correct charge' do
      payment = FactoryGirl.create(:payment_with_credit_card, amount: 600_00)
      user = payment.user
      sign_in user
      visit payments_path
      expect(page).to have_content 617.92
    end
  end

  context 'with upfront payment due', :vcr do
    it 'only shows a link to make an upfront payment' do
      user = FactoryGirl.create(:user_with_verified_bank_account)
      sign_in user
      visit payments_path
      expect(page).to have_link('Make upfront payment', href: new_upfront_payment_path)
      expect(page).to_not have_link('Start recurring payments', href: new_recurring_payment_path)
    end
  end

  context 'with no upfront payment due', :vcr do
    it "doesn't show a link to make an upfront payment" do
      plan = FactoryGirl.create(:recurring_plan_with_no_upfront_payment)
      user = FactoryGirl.create(:user, plan: plan)
      sign_in user
      visit payments_path
      expect(page).to_not have_link('Make upfront payment', href: new_upfront_payment_path)
    end
  end

  context 'with recurring payments not active', :vcr do
    it 'shows a link to start recurring payments' do
      plan = FactoryGirl.create(:recurring_plan_with_no_upfront_payment)
      user = FactoryGirl.create(:user, plan: plan)
      sign_in user
      visit payments_path
      expect(page).to have_link('Start recurring payments', href: new_recurring_payment_path)
    end
  end

  context 'with recurring payments active', :vcr do
    it "doesn't show a link to start recurring payments" do
      user = FactoryGirl.create(:user_with_recurring_active)
      sign_in user
      visit payments_path
      expect(page).to_not have_link('Start recurring payments', href: new_recurring_payment_path)
    end
  end
end

