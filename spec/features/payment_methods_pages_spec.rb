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
    it "shows payment method as pending with no 'Make Primary' button" do
      student = FactoryGirl.create(:user_with_unverified_bank_account)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Pending"
      expect(page).to_not have_button "Make Primary"
      expect(page).to_not have_content "✓"
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
      expect(page).to_not have_button "Make Primary"
    end

    it "shows verified bank account as primary and verified" do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "✓"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Verified"
      expect(page).to_not have_button "Make Primary"
    end
  end

  context 'after an additional payment method has been added', :vcr do
    it "shows additional payment method with option to 'Make Primary'" do
      student = FactoryGirl.create(:user_with_credit_card)
      bank_account = FactoryGirl.create(:verified_bank_account, student: student)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "xxxxxx0002"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Verified"
      expect(page).to have_button "Make Primary"
    end
  end
end

describe 'change primary payment method', :vcr do
  it "displays the new primary payment method and shows confirmation message" do
    student = FactoryGirl.create(:user_with_credit_card)
    bank_account = FactoryGirl.create(:verified_bank_account, student: student)
    sign_in student
    visit payment_methods_path
    click_on 'Make Primary'
    expect(page.find('tr.info')).to have_content "Bank account"
    expect(page).to have_content "Primary payment method has been updated."
  end
end
