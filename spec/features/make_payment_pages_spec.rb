require 'rails_helper'

feature 'Student makes an upfront payment' do
  context 'with a valid credit card', :vcr do
    it "shows successful payment message" do
      student = FactoryGirl.create(:user_with_credit_card)
      sign_in student
      visit payments_path
      click_on "Make upfront payment"
      expect(page).to have_content "Thank You! Your upfront payment has been made."
    end
  end

  context 'with an invalid credit card', :vcr do
    it "shows error message" do
      student = FactoryGirl.create(:user_with_invalid_credit_card)
      sign_in student
      visit payments_path
      click_on "Make upfront payment"
      expect(page).to have_content "R758: Account Frozen. Your request id is"
    end
  end
end

feature 'Student starts recurring payments' do
  context 'with a valid bank account', :vcr do
    it "shows successful payment message" do
      student = FactoryGirl.create(:user_with_upfront_payment)
      sign_in student
      visit payments_path
      click_on "Start recurring payments"
      expect(page).to have_content "Thank You! Your first recurring payment has been made."
    end
  end

  context 'with an invalid credit card', :vcr do
    it "shows error message" do
      plan = FactoryGirl.create(:recurring_plan_with_no_upfront_payment)
      student = FactoryGirl.create(:user_with_invalid_credit_card, plan: plan)
      sign_in student
      visit payments_path
      click_on "Start recurring payments"
      expect(page).to have_content "R758: Account Frozen. Your request id is"
    end
  end
end
