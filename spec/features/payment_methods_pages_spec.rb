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

  context 'after a bank account is added but not verified', :vcr do
    it "shows payment method as pending and non-primary" do
      student = FactoryGirl.create(:user_with_unverified_bank_account)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Pending"
      expect(page).to have_content "Make Primary"
    end
  end

  context 'after a primary payment method has been added', :vcr do
    it "shows credit card as primary and verified" do
      student = FactoryGirl.create(:user_with_credit_card)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxxxxxxxx1111"
      expect(page).to have_content "✓"
      expect(page).to have_content "Credit card"
      expect(page).to have_content "Verified"
      expect(page).to_not have_content "Make Primary"
    end

    it "shows verified bank account as primary and verified" do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "✓"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Verified"
      expect(page).to_not have_content "Make Primary"
    end
  end

  context 'after an additional payment method has been added', :vcr do
    before do
      student = FactoryGirl.create(:user_with_credit_card)
      bank_account = FactoryGirl.create(:bank_account, student: student)
      sign_in student
      visit payment_methods_path
    end

    it "shows additional payment method as non-primary" do
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Make Primary"
    end

    it "shows unverified bank account as pending" do
      expect(page).to have_content "Pending"
    end
  end
end
