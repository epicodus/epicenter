feature 'Viewing payment index page' do
  scenario 'as a guest' do
    student = FactoryGirl.create(:student)
    visit student_payments_path(student)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content "Looks like you haven't made any payments yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_bank_account, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Pending"
        expect(page).to have_content "Bank account ending in 6789"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
        FactoryGirl.create(:payment_with_credit_card, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 618.21
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
      end
    end

    context 'with upfront payment due using a bank account', :vcr do
      it 'only shows a link to make an upfront payment with correct amount' do
        plan = FactoryGirl.create(:upfront_payment_only_plan, upfront_amount: 200_00)
        student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com', plan: plan)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Make upfront payment of $200.00')
      end
    end

    context 'with upfront payment due using a credit card', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        plan = FactoryGirl.create(:upfront_payment_only_plan, upfront_amount: 200_00)
        student = FactoryGirl.create(:user_with_credit_card, plan: plan)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Make upfront payment of $206.27')
      end
    end
  end
end
