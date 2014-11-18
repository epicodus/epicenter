feature 'Balanced callback occurs' do
  let(:session_driver) { Capybara.current_session.driver }

  before(:each) do
    student = FactoryGirl.create(:user_with_verified_bank_account)
    login_as(student, scope: :student)
    visit payments_path
    click_on "Make upfront payment"
  end

  context "with a status of 'debit.succeeded'", :vcr do
    it "updates the payment to 'succeeded'" do
      payment_uri = Payment.last.payment_uri
      session_driver.submit :post, "/balanced_callbacks", balanced_callback_debit_succeeded_json(payment_uri)
      visit payments_path
      expect(page).to have_content "Succeeded"
    end
  end

  context "with a status of 'debit.failed'", :vcr do
    it "updates the payment to 'Failed'" do
      payment_uri = Payment.last.payment_uri
      session_driver.submit :post, "/balanced_callbacks", balanced_callback_debit_failed_json(payment_uri)
      visit payments_path
      expect(page).to have_content "Failed"
    end
  end
end
