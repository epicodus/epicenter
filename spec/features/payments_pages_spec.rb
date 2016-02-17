feature 'Viewing payment index page' do
  scenario 'as a guest' do
    student = FactoryGirl.create(:student)
    visit student_payments_path(student)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    scenario "without a primary payment method" do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      login_as(student, scope: :student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payment methods"
    end

    context "viewing another student's payments page", :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card)
        student_2 = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student_2)
        expect(page).to have_content "You are not authorized to access this page."
      end
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
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

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario "for a student without a primary payment method" do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      visit student_payments_path(student)
      expect(page).to have_content "Payments for #{student.name}"
      expect(page).to have_content "No payments have been made yet."
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_credit_card)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_bank_account, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Pending"
        expect(page).to have_content "Bank account ending in 6789"
        expect(page).to have_content "Issue refund"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
        FactoryGirl.create(:payment_with_credit_card, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 618.21
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
        expect(page).to have_content "Issue refund"
      end
    end

    context 'after a refund has been issued to a bank account payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_bank_account, amount: 600_00, student: student)
        payment.update(refund_amount: 300_00)
        visit student_payments_path(student)
        expect(page).to have_content '$300.00'
      end
    end

    context 'after a refund has been issued to a credit card payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_credit_card, amount: 600_00, student: student)
        payment.update(refund_amount: 200_00)
        visit student_payments_path(student)
        expect(page).to have_content '$200.00'
      end
    end

    scenario 'via search', :vcr, :stub_mailgun do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      visit root_path
      fill_in 'search', with: 'test@test.com'
      click_on 'student-search'
      click_on 'Manage payments'
      expect(page).to have_content "Payments for #{student.name}"
    end
  end
end

feature 'viewing payment show page', :vcr, :stripe_mock, :stub_mailgun do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com') }
  let(:payment) { FactoryGirl.create(:payment_with_credit_card, student: student) }

  scenario 'as a guest' do
    visit payment_path(payment)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    scenario "viewing another student's page" do
      student_2 = FactoryGirl.create(:user_with_credit_card, email: 'test2@test.com')
      payment_2 = FactoryGirl.create(:payment_with_credit_card, student: student_2)
      login_as(student, scope: :student)
      visit payment_path(payment_2)
      expect(page).to have_content "You are not authorized to access this page."
    end

    scenario 'viewing their personal payment page' do
      login_as(student, scope: :student)
      visit payment_path(payment)
      expect(page).to have_content "Payment for #{student.name}"
      expect(page).to have_content "Total amount: $1.32"
      expect(page).to_not have_content 'Refund amount'
    end
  end

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    scenario 'before a refund is issued' do
      visit payment_path(payment)
      expect(page).to have_content 'Refund amount'
      expect(page).to have_css '#refund-button'
    end
  end
end

feature 'issuing a refund as an admin', :vcr, :stub_mailgun do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com') }
  let(:payment) { FactoryGirl.create(:payment_with_credit_card, student: student) }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully' do
    visit payment_path(payment)
    fill_in 'payment_refund_amount', with: 60
    click_on 'Issue refund'
    expect(page).to have_content "Refund successfully issued for #{payment.student.name}."
    expect(page).to have_content '$0.60'
  end

  scenario 'unsuccessfully' do
    visit payment_path(payment)
    fill_in 'payment_refund_amount', with: 200
    click_on 'Issue refund'
    expect(page).to have_content 'Refund amount cannot be greater than the total payment amount.'
  end
end
