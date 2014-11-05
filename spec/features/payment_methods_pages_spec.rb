require 'rails_helper'

feature 'Student views payment methods page' do
  context 'before any payment methods have been added', :vcr do
    it "doesn't show any payment methods" do
      student = FactoryGirl.create(:student)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "Looks like you haven't added any payment methods yet."
    end
  end

  context 'after a primary payment method has been added', :vcr do
    it "shows payment method as primary" do
      student = FactoryGirl.create(:user_with_credit_card)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxxxxxxxx1111"
      expect(page).to have_content "✓"
      expect(page).to have_content "Credit card"
      expect(page).to_not have_content "Make Primary"
    end
  end

  context 'after an additional payment method has been added', :vcr do
    it "shows additional payment method as non-primary" do
      student = FactoryGirl.create(:user_with_credit_card)
      bank_account = FactoryGirl.create(:bank_account, student: student)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Make Primary"
    end
  end
end
