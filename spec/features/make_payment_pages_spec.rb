feature 'Student makes an upfront payment' do
  context 'with a valid credit card', :vcr, :stripe_mock, :stub_mailgun, :stub_less_accounting do
    it "shows successful payment message" do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      login_as(student, scope: :student)
      visit student_payments_path(student)
      click_on "Make upfront payment"
      expect(page).to have_content "Thank You! Your upfront payment has been made."
    end
  end
end
