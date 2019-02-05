feature 'Student makes an upfront payment' do
  context 'with a valid credit card', :vcr, :stripe_mock, :stub_mailgun do
    it "shows successful payment message" do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      login_as(student, scope: :student)
      visit student_payments_path(student)
      click_on "Charge $7,107.00 to my credit card ending in 4242"
      expect(page).to have_content "Thank You! Your payment has been made."
    end
  end
end
