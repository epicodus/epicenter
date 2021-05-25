feature 'Student makes an upfront payment' do
  context 'with a valid credit card', :vcr, :stripe_mock, :stub_mailgun do
    it "shows successful payment message" do
      student = FactoryBot.create(:student, :with_plan, :with_credit_card, :with_ft_cohort, email: 'example@example.com')
      login_as(student, scope: :student)
      visit student_payments_path(student)
      click_on "Charge $8,034.00 to my credit card ending in 4242"
      expect(page).to have_content "Thank You! Your payment has been made."
    end
  end
end
