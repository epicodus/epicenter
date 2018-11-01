feature 'Student makes an upfront payment' do
  context 'with a valid credit card', :vcr, :stripe_mock, :stub_mailgun do
    it "shows successful payment message" do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      login_as(student, scope: :student)
      visit student_payments_path(student)
      click_on "Make upfront payment"
      expect(page).to have_content "Thank You! Your upfront payment has been made."
    end
  end
end
