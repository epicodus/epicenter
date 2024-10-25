feature 'Student views payment methods page' do
  context 'before any payment methods have been added' do
    it "doesn't show any payment methods" do
      student = FactoryBot.create(:student, :with_all_documents_signed)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "How would you like to make payments for the class?"
      expect(page).to_not have_link "Make or review payments"
    end
  end

  context 'after a bank account is added but not verified' do
    it "shows 'Verify Account' button and does not show link to make payments", :vcr do
      student = FactoryBot.create(:student, :with_all_documents_signed, :with_unverified_bank_account)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "Bank account 6789"
      expect(page).to have_content "Bank account"
      expect(page).to have_link "Verify Account"
      expect(page).to_not have_button "Make Primary"
      expect(page).to_not have_content "✓"
      expect(page).to_not have_link "Make or review payments"
    end
  end

  context 'after a primary payment method has been added' do
    it "shows credit card as primary and shows link to make payments", :stripe_mock do
      student = FactoryBot.create(:student, :with_all_documents_signed, :with_credit_card)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "4242"
      expect(page).to have_content "✓"
      expect(page).to have_content "Credit card"
      expect(page).to have_content "Verified"
      expect(page).to_not have_button "Make Primary"
    end

    it "shows verified bank account as primary and verified", :vcr do
      student = FactoryBot.create(:student, :with_all_documents_signed, :with_verified_bank_account)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "6789"
      expect(page).to have_content "✓"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Verified"
      expect(page).to_not have_button "Make Primary"
    end
  end

  context 'after an additional payment method has been added', :vcr, :stripe_mock do
    it "shows additional payment method with option to 'Make Primary'" do
      student = FactoryBot.create(:student, :with_all_documents_signed, :with_credit_card)
      bank_account = FactoryBot.create(:verified_bank_account, student: student)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "4242"
      expect(page).to have_content "Bank account"
      expect(page).to have_content "Verified"
      expect(page).to have_button "Make Primary"
    end
  end
end

feature 'Guest views payments methods page' do
  it 'is not authorized' do
    visit payment_methods_path
    expect(page).to have_content 'need to sign in'
  end
end

describe 'change primary payment method', :vcr, :stripe_mock do
  it "displays the new primary payment method and shows confirmation message" do
    student = FactoryBot.create(:student, :with_all_documents_signed, :with_credit_card)
    bank_account = FactoryBot.create(:verified_bank_account, student: student)
    sign_in_as student
    visit payment_methods_path
    click_on 'Make Primary'
    expect(page.find('tr.info')).to have_content "Bank account"
    expect(page).to have_content "Primary payment method has been updated."
  end
end
