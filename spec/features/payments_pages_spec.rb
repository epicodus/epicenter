feature 'Viewing payment index page' do
  scenario 'as a guest' do
    student = FactoryBot.create(:student)
    visit student_payments_path(student)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    scenario "without a primary payment method" do
      student = FactoryBot.create(:user_with_all_documents_signed)
      login_as(student, scope: :student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payment methods"
    end

    context "viewing another student's payments page", :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card)
        student_2 = FactoryBot.create(:user_with_all_documents_signed_and_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student_2)
        expect(page).to have_content "You are not authorized to access this page."
      end
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:user_with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:user_with_verified_bank_account, email: 'example@example.com')
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
        student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 618.21
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
      end
    end

    context 'with upfront payment due using a bank account', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        student = FactoryBot.create(:user_with_verified_bank_account, email: 'example@example.com')
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Make upfront payment of $100.00')
      end
    end

    context 'with upfront payment due using a credit card', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        student = FactoryBot.create(:user_with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Make upfront payment of $103.28')
      end
    end

    describe 'sets category' do
      it 'sets category to upfront for first payment for student with 1 full-time course', :vcr, :stripe_mock, :stub_mailgun do
        student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Make upfront payment of $103.28'
        expect(student.payments.first.category).to eq 'upfront'
      end

      it 'sets category to upfront for first payment for student with 1 part-time course', :vcr, :stripe_mock, :stub_mailgun do
        student = FactoryBot.create(:part_time_student_with_payment_method, email: 'example@example.com')
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Make upfront payment of $103.28'
        expect(student.payments.first.category).to eq 'upfront'
      end
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario "for a student without a primary payment method" do
      student = FactoryBot.create(:user_with_all_documents_signed)
      visit student_payments_path(student)
      expect(page).to have_content "No payments have been made yet."
      expect(page).to have_content "No primary payment method has been selected"
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:user_with_credit_card)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
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
        student = FactoryBot.create(:student, email: 'example@example.com')
        payment = FactoryBot.create(:payment, amount: 600_00, student: student, offline: true)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Offline"
        expect(page).to_not have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 618.21
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
        expect(page).to have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a refund has been issued to a bank account payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_bank_account, amount: 600_00, student: student)
        payment.update(refund_amount: 300_00, refund_date: Date.today)
        visit student_payments_path(student)
        expect(page).to have_content '$300.00'
      end
    end

    context 'after a refund has been issued to a credit card payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        payment.update(refund_amount: 200_00, refund_date: Date.today)
        visit student_payments_path(student)
        expect(page).to have_content '$200.00'
      end
    end

    context 'after an offline refund has been issued', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
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
  let(:student) { FactoryBot.create(:user_with_all_documents_signed_and_credit_card) }

  before { login_as(admin, scope: :admin) }

  it 'sets category to refund for offline refunds' do
    visit student_payments_path(student)
    fill_in 'refund-offline-input', with: '600'
    fill_in 'refund-date-offline-input', with: Date.today
    click_on 'Offline refund'
    expect(student.payments.first.category).to eq 'refund'
  end
end

feature 'issuing a refund as an admin', :vcr, :stub_mailgun do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com') }
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
    expect(page).to have_content 'Refund amount ($200.00) is greater than charge amount ($103.28)'
  end

  scenario 'unsuccessfully with a negative amount' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: -16.46
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    click_on 'Refund'
    expect(page).to have_content 'Invalid positive integer'
  end
end

feature 'make a manual payment', :stripe_mock, :stub_mailgun do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com') }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully with cents', :vcr do
    visit student_payments_path(student)
    select student.primary_payment_method.description
    fill_in 'payment_amount', with: 1765.24
    click_on 'Manual payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Succeeded'
    expect(page).to have_content '$1,818.26'
  end

  scenario 'successfully with multiple payment methods', :vcr do
    other_payment_method = FactoryBot.create(:bank_account, student: student)
    visit student_payments_path(student)
    select other_payment_method.description
    fill_in 'payment_amount', with: 1765.24
    click_on 'Manual payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Pending'
    expect(page).to have_content '$1,765.24'
  end

  scenario 'successfully without cents', :vcr do
    visit student_payments_path(student)
    fill_in 'payment_amount', with: 1765
    click_on 'Manual payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Succeeded'
    expect(page).to have_content '$1,818.01'
  end

  scenario 'unsuccessfully with an improperly formatted amount', :js do
    visit student_payments_path(student)
    fill_in 'payment_amount', with: 60.1
    message = accept_prompt do
      click_on 'Manual payment'
    end
    expect(message).to eq 'Please enter a valid amount.'
  end

  scenario 'with an invalid amount (too high)' do
    visit student_payments_path(student)
    fill_in 'payment_amount', with: 9000
    click_on 'Manual payment'
    expect(page).to have_content 'Amount cannot be negative or greater than $8,500.'
  end

  scenario 'with an invalid amount (negative)' do
    visit student_payments_path(student)
    fill_in 'payment_amount', with: -100
    click_on 'Manual payment'
    expect(page).to have_content 'Amount cannot be negative or greater than $8,500.'
  end

  scenario 'with no primary payment method selected' do
    student = FactoryBot.create(:user_with_all_documents_signed)
    visit student_payments_path(student)
    expect(page).to have_content 'No primary payment method has been selected'
  end

  scenario 'successfully with mismatching Epicenter and Close.io emails', :vcr do
    student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'wrong_email@test.com')
    visit student_payments_path(student)
    select student.primary_payment_method.description
    fill_in 'payment_amount', with: 1765.24
    click_on 'Manual payment'
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Succeeded'
    expect(page).to have_content '$1,818.26'
  end
end

feature 'make an offline payment', :js, :vcr do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed_and_credit_card) }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully with cents' do
    visit student_payments_path(student)
    check 'offline-payment-checkbox'
    fill_in 'Notes', with: 'Test offline payment'
    fill_in 'payment_amount', with: 60.18
    click_on 'Manual payment'
    wait = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoAlertPresentError
    alert = wait.until { page.driver.browser.switch_to.alert }
    alert.accept
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Offline'
    expect(page).to have_content '$60.18'
  end
end

feature "Responds to callback from Zapier with qbo doc_numbers", :js do
  scenario "and instantiates PaymentCallback model" do
    payment = FactoryBot.create(:payment_with_credit_card)
    host = Capybara.current_session.server.host
    port = Capybara.current_session.server.port
    payload = { 'paymentId': payment.id.to_s, 'docNumber': '1A'}
    RestClient.post("#{host}:#{port}/payment_callbacks", payload.to_json, {content_type: :json, accept: :json})
    expect(payment.reload.qbo_doc_numbers).to eq ['1A']
  end
end
