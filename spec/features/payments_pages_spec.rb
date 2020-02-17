feature 'Viewing payment index page' do
  scenario 'as a guest' do
    student = FactoryBot.create(:student)
    visit student_payments_path(student)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    scenario "without a primary payment method" do
      student = FactoryBot.create(:student_with_all_documents_signed)
      login_as(student, scope: :student)
      visit student_payments_path(student)
      expect(page).to have_content "How would you like to make payments for the class?"
    end

    context "viewing another student's payments page", :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card)
        student_2 = FactoryBot.create(:student_with_all_documents_signed_and_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student_2)
        expect(page).to have_content "You are not authorized to access this page."
      end
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:student_with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_verified_bank_account, email: 'example@example.com')
        FactoryBot.create(:payment_with_bank_account, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Pending"
        expect(page).to have_content "Bank account ending in 6789"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 618.00
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
      end
    end

    context 'with payment plan and upfront payment due using a bank account', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        student = FactoryBot.create(:student_with_verified_bank_account, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Charge $100.00 to my bank account ending in 6789')
      end
    end

    context 'with payment plan and upfront payment due using a credit card', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Charge $103.00 to my credit card ending in 4242')
      end
    end

    context 'with no payment plan set' do
      context 'for full-time student' do
        let!(:upfront_plan) { FactoryBot.create(:upfront_plan) }
        let!(:standard_plan) { FactoryBot.create(:standard_plan) }
        let!(:loan_plan) { FactoryBot.create(:loan_plan) }
        let!(:grant_plan) { FactoryBot.create(:grant_plan) }
        let(:student) { FactoryBot.create(:student_with_verified_bank_account, plan: nil) }

        before do
          login_as(student, scope: :student)
          visit student_payments_path(student)
        end

        it 'shows payment plan selection options' do
          expect(page).to have_button 'Up-front discount'
          expect(page).to have_button 'Standard plan'
          expect(page).to have_button 'Loan'
          expect(page).to have_button '3rd-party grant'
        end

        it 'shows correct payment button when upfront payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Up-front discount'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $6,900.00'
        end

        it 'shows correct payment button when standard payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Standard plan'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $100.00'
        end

        it 'shows correct payment button when loan payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Loan'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $100.00'
        end

        it 'shows correct payment button when 3rd-party grant payment plan selected', :stripe_mock, :stub_mailgun do
          click_on '3rd-party grant'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $100.00'
        end
      end

      context 'for part-time track student' do
        let!(:upfront_plan) { FactoryBot.create(:upfront_plan) }
        let!(:parttime_track_plan) { FactoryBot.create(:parttime_track_plan) }
        let!(:loan_plan) { FactoryBot.create(:loan_plan) }
        let(:cohort) { FactoryBot.create(:part_time_js_react_cohort) }
        let(:student) { FactoryBot.create(:student_with_verified_bank_account, plan: nil, courses: []) }

        before do
          student.cohort = cohort
          login_as(student, scope: :student)
          visit student_payments_path(student)
        end

        it 'shows payment plan selection options' do
          expect(page).to have_button 'Up-front payment'
          expect(page).to_not have_button 'Standard plan'
          expect(page).to have_button 'Loan'
          expect(page).to_not have_button '3rd-party grant'
        end

        it 'shows correct payment button when upfront payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Up-front payment'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $5,400.00'
        end

        it 'shows correct payment button when loan payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Loan'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $100.00'
        end
      end
    end

    describe 'sets category', :stripe_mock, :stub_mailgun do
      it 'sets category to upfront for first payment for student with 1 full-time course' do
        student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Charge $103.00'
        expect(student.payments.first.category).to eq 'upfront'
      end

      it 'sets category to upfront for first payment for student with 1 part-time course' do
        student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:parttime_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Charge $103.00'
        expect(student.payments.first.category).to eq 'upfront'
      end
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario "for a student without a primary payment method" do
      student = FactoryBot.create(:student_with_all_documents_signed)
      visit student_payments_path(student)
      expect(page).to have_content "No payments have been made yet."
      expect(page).to have_content "No primary payment method has been selected"
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:student_with_credit_card)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_bank_account, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Pending"
        expect(page).to have_content "Bank account ending in 6789"
        expect(page).to have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after an offline payment has been made', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status but no refund form' do
        student = FactoryBot.create(:student_with_cohort, email: 'example@example.com')
        payment = FactoryBot.create(:payment, amount: 600_00, student: student, offline: true)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Offline"
        expect(page).to_not have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 618.00
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
        expect(page).to have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a refund has been issued to a bank account payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_bank_account, amount: 600_00, student: student)
        payment.update(refund_amount: 300_00, refund_date: Date.today)
        visit student_payments_path(student)
        expect(page).to have_content '$300.00'
      end
    end

    context 'after a refund has been issued to a credit card payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        payment.update(refund_amount: 200_00, refund_date: Date.today)
        visit student_payments_path(student)
        expect(page).to have_content '$200.00'
      end
    end

    context 'after an offline refund has been issued', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 0, refund_amount: -600_00, student: student, offline: true)
        visit student_payments_path(student)
        expect(page).to have_content '$0.00'
        expect(page).to have_content '$600.00'
      end
    end
  end
end

feature 'issuing an offline refund as an admin', :vcr do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student_with_all_documents_signed_and_credit_card) }

  before { login_as(admin, scope: :admin) }

  it 'sets category to refund for offline refunds' do
    visit student_payments_path(student)
    fill_in 'refund-offline-input', with: '600'
    fill_in 'refund-date-offline-input', with: Date.today
    click_on 'Offline refund'
    expect(student.payments.first.category).to eq 'refund'
  end

  it 'shows warning if starting cohort does not match current cohort' do
    student.cohort = FactoryBot.create(:intro_only_cohort)
    student.save
    visit student_payments_path(student)
    expect(page).to have_content 'Starting Cohort does not match Current Cohort'
  end

end

feature 'issuing a refund as an admin', :vcr, :stub_mailgun do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com') }
  let!(:payment) { FactoryBot.create(:payment_with_credit_card, amount: 100_00, student: student) }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully without cents' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 60
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    click_on 'Refund'
    expect(page).to have_content "Refund successfully issued for #{payment.student.name}."
    expect(page).to have_content '$60.00'
  end

  scenario 'successfully with cents' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 60.18
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    click_on 'Refund'
    expect(page).to have_content "Refund successfully issued for #{payment.student.name}."
    expect(page).to have_content '$60.18'
  end

  scenario 'unsuccessfully with an improperly formatted amount', :js do
    visit student_payments_path(student)
    page.find_by_id('show-refund-form-button').click
    fill_in "refund-#{payment.id}-input", with: 60.1
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    message = accept_prompt do
      click_on 'Refund'
    end
    expect(message).to eq 'Please enter a valid amount.'
  end

  scenario 'unsuccessfully with an amount that is too large' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 200
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    click_on 'Refund'
    expect(page).to have_content 'Refund amount ($200.00) is greater than charge amount ($103.00)'
  end

  scenario 'unsuccessfully with a negative amount' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: -16.46
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    click_on 'Refund'
    expect(page).to have_content 'Please correct these problems'
  end

  scenario 'shows warning if starting cohort does not match current cohort' do
    student.cohort = FactoryBot.create(:intro_only_cohort)
    student.save
    visit student_payments_path(student)
    expect(page).to have_content 'Starting Cohort does not match Current Cohort'
  end
end

feature 'make a manual stripe payment', :stripe_mock, :stub_mailgun do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com') }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully with cents', :vcr do
    visit student_payments_path(student)
    select student.primary_payment_method.description
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 1765.24
    end
    click_on 'Stripe payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Succeeded'
    expect(page).to have_content '$1,818.19'
  end

  scenario 'successfully with multiple payment methods', :vcr do
    other_payment_method = FactoryBot.create(:bank_account, student: student)
    visit student_payments_path(student)
    select other_payment_method.description
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 1765.24
    end
    click_on 'Stripe payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Pending'
    expect(page).to have_content '$1,765.24'
  end

  scenario 'successfully without cents', :vcr do
    visit student_payments_path(student)
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 1765
    end
    click_on 'Stripe payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Succeeded'
    expect(page).to have_content '$1,817.95'
  end

  scenario 'unsuccessfully with an improperly formatted amount', :js do
    visit student_payments_path(student)
    click_on 'Stripe Payment'
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 60.1
    end
    message = accept_prompt do
      click_on 'Stripe payment'
    end
    expect(message).to eq 'Please enter a valid amount.'
  end

  scenario 'with an invalid amount (too high)' do
    visit student_payments_path(student)
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 9000
    end
    click_on 'Stripe payment'
    expect(page).to have_content 'Amount cannot be negative or greater than $8,800.'
  end

  scenario 'with an invalid amount (negative)' do
    visit student_payments_path(student)
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: -100
    end
    click_on 'Stripe payment'
    expect(page).to have_content 'Amount cannot be negative or greater than $8,800.'
  end

  scenario 'with no primary payment method selected' do
    student = FactoryBot.create(:student_with_all_documents_signed)
    visit student_payments_path(student)
    expect(page).to have_content 'No primary payment method has been selected'
  end

  scenario 'successfully with mismatching Epicenter and Close.io emails', :vcr do
    student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'wrong_email@test.com')
    visit student_payments_path(student)
    select student.primary_payment_method.description
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 1765.24
    end
    click_on 'Stripe payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Succeeded'
    expect(page).to have_content '$1,818.19'
  end
end

feature 'make an offline payment', :js, :vcr do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student_with_all_documents_signed_and_credit_card) }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully with cents' do
    visit student_payments_path(student)
    click_on 'Offline Payment'
    fill_in 'Notes', with: 'Test offline payment'
    within '#offline-payment-form' do
      fill_in 'payment_amount', with: 60.18
    end
    click_on 'Offline payment'
    wait = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoSuchAlertError
    alert = wait.until { page.driver.browser.switch_to.alert }
    alert.accept
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Offline'
    expect(page).to have_content '$60.18'
  end
end

feature "Responds to callback from Zapier with qbo doc_numbers", :js do
  scenario "and instantiates PaymentCallback model" do
    student = FactoryBot.create(:student_with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student)
    host = Capybara.current_session.server.host
    port = Capybara.current_session.server.port
    payload = { 'paymentId': payment.id.to_s, 'docNumber': '1A'}
    RestClient.post("#{host}:#{port}/payment_callbacks", payload.to_json, {content_type: :json, accept: :json})
    expect(payment.reload.qbo_doc_numbers).to eq ['1A']
  end
end

feature 'make a cost adjustment' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student_with_all_documents_signed_and_credit_card) }

  context 'as a student' do
    before { login_as(student, scope: :student) }

    it 'does not allow student to view or make tuition adjustments' do
      visit student_payments_path(student)
      expect(page).to_not have_content 'Tuition adjustments'
      expect(page).to_not have_content 'Adjust student tuition'
      expect(page).to_not have_content 'Adjust student cost'
    end
  end

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    it 'allows admin to make tuition adjustment without cents', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      find('#show-student-tuition-adjustment').click
      fill_in 'cost_adjustment_amount', with: 100
      fill_in 'cost_adjustment_reason', with: 'test adjustment'
      click_button 'Adjust student cost'
      expect(student.cost_adjustments.first.amount).to eq 100_00
      expect(student.cost_adjustments.first.reason).to eq 'test adjustment'
    end

    it 'allows admin to make tuition adjustment with cents', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      find('#show-student-tuition-adjustment').click
      fill_in 'cost_adjustment_amount', with: '100.50'
      fill_in 'cost_adjustment_reason', with: 'test adjustment'
      click_button 'Adjust student cost'
      expect(student.cost_adjustments.first.amount).to eq 100_50
      expect(student.cost_adjustments.first.reason).to eq 'test adjustment'
    end

    it 'allows admin to make tuition adjustment with negative amount without cents', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      find('#show-student-tuition-adjustment').click
      fill_in 'cost_adjustment_amount', with: '-100'
      fill_in 'cost_adjustment_reason', with: 'test adjustment'
      click_button 'Adjust student cost'
      expect(student.cost_adjustments.first.amount).to eq -100_00
      expect(student.cost_adjustments.first.reason).to eq 'test adjustment'
    end

    it 'allows admin to make tuition adjustment with negative amount with cents', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      find('#show-student-tuition-adjustment').click
      fill_in 'cost_adjustment_amount', with: '-100.50'
      fill_in 'cost_adjustment_reason', with: 'test adjustment'
      click_button 'Adjust student cost'
      expect(student.cost_adjustments.first.amount).to eq -100_50
      expect(student.cost_adjustments.first.reason).to eq 'test adjustment'
    end

    it 'does not allow tuition adjustment with invalid amount', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      find('#show-student-tuition-adjustment').click
      fill_in 'cost_adjustment_amount', with: '100.5'
      fill_in 'cost_adjustment_reason', with: 'test adjustment'
      click_button 'Adjust student cost'
      expect(student.cost_adjustments.any?).to eq false
    end

    it 'allows admin to view tuition adjustments' do
      cost_adjustment = FactoryBot.create(:cost_adjustment, student: student)
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      expect(page).to have_content 'Tuition adjustments'
      expect(page).to have_content '$100'
      expect(page).to have_content 'test adjustment'
    end

    it 'allows admin to delete tuition adjustment', :js do
      cost_adjustment = FactoryBot.create(:cost_adjustment, student: student)
      visit student_payments_path(student)
      click_on 'Tuition Adjustments'
      find("#remove-cost-adjustment-#{cost_adjustment.id}").click
      wait = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoSuchAlertError
      alert = wait.until { page.driver.browser.switch_to.alert }
      alert.accept
      expect(page).to have_content 'Deleted cost adjustment'
      expect(page).to_not have_content 'Tuition adjustments'
      expect(page).to_not have_content 'test adjustment'
    end
  end
end
