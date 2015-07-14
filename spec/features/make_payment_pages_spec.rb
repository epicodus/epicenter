feature 'Student makes an upfront payment' do
  context 'with a valid credit card', :vcr do
    it "shows successful payment message" do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      login_as(student, scope: :student)
      visit payments_path
      click_on "Make upfront payment"
      expect(page).to have_content "Thank You! Your upfront payment has been made."
    end
  end
end

feature 'Student starts recurring payments' do
  context 'with a valid bank account', :vcr do
    it "shows successful payment message" do
      student = FactoryGirl.create(:user_with_upfront_payment, email: 'test@test.com')
      login_as(student, scope: :student)
      visit payments_path
      click_on "Start recurring payments"
      expect(page).to have_content "Thank You! Your first recurring payment has been made."
    end
  end
end
