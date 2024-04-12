feature 'Viewing payment index page' do
  scenario 'as a guest' do
    student = FactoryBot.create(:student)
    visit student_payments_path(student)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    scenario "without a primary payment method" do
      student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed)
      login_as(student, scope: :student)
      visit student_payments_path(student)
      expect(page).to have_content "How would you like to make payments for the class?"
    end

    context "viewing another student's payments page", :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card)
        student_2 = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student_2)
        expect(page).to have_content "You are not authorized to access this page."
      end
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_verified_bank_account, email: 'example@example.com')
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
        student = FactoryBot.create(:student, :with_ft_cohort, :with_all_documents_signed, :with_credit_card, email: 'example@example.com')
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
        student = FactoryBot.create(:student, :with_ft_cohort, :with_verified_bank_account, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Charge $100.00 to my bank account ending in 6789')
      end
    end

    context 'with payment plan and upfront payment due using a credit card', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
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
        let!(:isa_plan) { FactoryBot.create(:isa_plan) }
        let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_verified_bank_account, plan: nil) }

        before do
          login_as(student, scope: :student)
          visit student_payments_path(student)
        end

        it 'shows payment plan selection options' do
          expect(page).to have_button 'Up-Front Discount'
          expect(page).to have_button 'Standard Tuition'
          expect(page).to have_button 'Loan'
          expect(page).to have_button 'Income Share Agreement'
        end

        it 'shows correct payment button when upfront payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Up-Front Discount'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $8,700.00'
        end

        it 'shows correct payment button when standard payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Standard Tuition'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $100.00'
        end

        it 'shows correct payment button when loan payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Loan'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $100.00'
        end

        it 'shows correct payment button when isa payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Income Share Agreement'
          expect(page).to have_content 'selected the ISA payment plan'
          expect(page).to_not have_button 'Charge $100.00'
        end
      end

      context 'for part-time track student' do
        let!(:upfront_plan) { FactoryBot.create(:upfront_plan) }
        let!(:standard_plan) { FactoryBot.create(:standard_plan) }
        let!(:loan_plan) { FactoryBot.create(:loan_plan) }
        let(:cohort) { FactoryBot.create(:pt_c_react_cohort) }
        let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_verified_bank_account, plan: nil, courses: []) }

        before do
          student.cohort = cohort
          login_as(student, scope: :student)
          visit student_payments_path(student)
        end

        it 'shows payment plan selection options' do
          expect(page).to have_button 'Up-Front Discount'
          expect(page).to have_button 'Standard Tuition'
          expect(page).to have_button 'Loan'
        end

        it 'shows correct payment button when upfront payment plan selected', :stripe_mock, :stub_mailgun do
          click_on 'Up-Front Discount'
          expect(page).to have_content 'Payment plan selected. Please make payment below.'
          expect(page).to have_button 'Charge $8,700.00'
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
        student = FactoryBot.create(:student, :with_ft_cohort, :with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Charge $103.00'
        expect(student.payments.first.category).to eq 'upfront'
      end

      it 'sets category to upfront for first payment for student with 1 part-time course' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:parttime_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Charge $103.00'
        expect(student.payments.first.category).to eq 'upfront'
      end
    end

    describe 'sets cohort', :stripe_mock, :stub_mailgun do
      it 'for student upfront payment' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_credit_card, email: 'example@example.com', plan: FactoryBot.create(:free_intro_plan))
        login_as(student, scope: :student)
        visit student_payments_path(student)
        click_on 'Charge $103.00'
        expect(student.payments.first.cohort).to eq student.cohort
      end
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    before { login_as(admin, scope: :admin) }

    scenario "for a student without a primary payment method" do
      student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed)
      visit student_payments_path(student)
      expect(page).to have_content "No payments have been made yet."
      expect(page).to have_content "No primary payment method has been selected"
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_credit_card)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_verified_bank_account, email: 'example@example.com')
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
        student = FactoryBot.create(:student, :with_ft_cohort, email: 'example@example.com')
        payment = FactoryBot.create(:payment, amount: 600_00, student: student, offline: true)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Offline"
        expect(page).to_not have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card, email: 'example@example.com')
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
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_verified_bank_account, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_bank_account, amount: 600_00, student: student)
        payment.update(refund_amount: 300_00, refund_date: Date.today)
        visit student_payments_path(student)
        expect(page).to have_content '$300.00'
      end
    end

    context 'after a refund has been issued to a credit card payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 600_00, student: student)
        payment.update(refund_amount: 200_00, refund_date: Date.today)
        visit student_payments_path(student)
        expect(page).to have_content '$200.00'
      end
    end

    context 'after an offline refund has been issued', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card, email: 'example@example.com')
        payment = FactoryBot.create(:payment_with_credit_card, amount: 0, refund_amount: -600_00, student: student, offline: true)
        visit student_payments_path(student)
        expect(page).to have_content '$0.00'
        expect(page).to have_content '$600.00'
      end
    end
  end
end

xfeature 'issuing an offline refund as an admin', :vcr do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_all_documents_signed, :with_upfront_payment) }

  before { login_as(admin, scope: :admin) }

  it 'is unavailable when no payment has made' do
    student_without_payments = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card)
    visit student_payments_path(student_without_payments)
    expect(page).to_not have_content 'Offline refund'
  end

  it 'displays cohort in offline refund section if present' do
    visit student_payments_path(student)
    section = all(:css, '.offline-refund-form-info').first
    expect(section).to have_content student.course.cohort.description
  end

  it 'displays last day attended in offline refund section if present' do
    travel_to student.course.start_date do
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
    end
    visit student_payments_path(student)
    section = all(:css, '.offline-refund-form-info').first
    expect(section).to have_content "Date of last sign in: #{student.course.start_date.to_s}"
  end

  it 'displays no course in offline refund section if not course present' do
    student.enrollments.delete_all
    visit student_payments_path(student)
    section = all(:css, '.offline-refund-form-info').first
    expect(section).to have_content 'no course'
  end

  it 'displays no attendance records in offline refund section if none present' do
    visit student_payments_path(student)
    section = all(:css, '.offline-refund-form-info').first
    expect(section).to have_content 'Date of last sign in: no attendance records'
  end

  it 'sets category to refund for offline refunds' do
    payment = FactoryBot.create(:payment, student: student, offline: true)
    visit student_payments_path(student)
    fill_in 'refund-offline-input', with: '600'
    fill_in 'refund-date-offline-input', with: Date.today
    select payment.full_description, from: "payment_linked_payment_id"
    click_on 'Offline refund'
    expect(student.payments.find_by(amount: 0).category).to eq 'refund'
  end

  it 'sets cohort to cohort of linked payment' do
    payment = FactoryBot.create(:payment, student: student, offline: true)
    visit student_payments_path(student)
    fill_in 'refund-offline-input', with: '600'
    fill_in 'refund-date-offline-input', with: Date.today
    select payment.full_description, from: "payment_linked_payment_id"
    click_on 'Offline refund'
    expect(student.payments.find_by(amount: 0).cohort).to eq payment.cohort
  end

  it 'shows warning if starting cohort does not match current cohort' do
    student.cohort = FactoryBot.create(:pt_intro_cohort)
    student.save
    visit student_payments_path(student)
    expect(page).to have_content 'Starting Cohort does not match Current Cohort'
  end

  scenario 'unsuccessfully with refund date after cohort end' do
    payment = FactoryBot.create(:payment, student: student, offline: true)
    visit student_payments_path(student)
    fill_in 'refund-offline-input', with: '600'
    fill_in 'refund-date-offline-input', with: student.cohort.end_date + 1.week
    select payment.full_description, from: "payment_linked_payment_id"
    click_on 'Offline refund'
    expect(page).to have_content 'Please correct these problems'
  end

  scenario 'updates refund date if before cohort start' do
    payment = FactoryBot.create(:payment, student: student, offline: true)
    visit student_payments_path(student)
    fill_in 'refund-offline-input', with: '600'
    fill_in 'refund-date-offline-input', with: student.cohort.start_date - 1.week
    select payment.full_description, from: "payment_linked_payment_id"
    click_on 'Offline refund'
    expect(student.payments.last.refund_date).to eq student.cohort.start_date
  end
end

feature 'issuing a refund as an admin', :vcr, :stub_mailgun do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card, email: 'example@example.com') }
  let!(:payment) { FactoryBot.create(:payment_with_credit_card, amount: 100_00, student: student) }

  before { login_as(admin, scope: :admin) }

  it 'displays cohort in refund section if present' do
    visit student_payments_path(student)
    section = all(:css, '.refund-form-info').first
    expect(section).to have_content student.course.cohort.description
  end

  it 'displays last day attended in refund section if present' do
    travel_to student.course.start_date do
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
    end
    visit student_payments_path(student)
    section = all(:css, '.refund-form-info').first
    expect(section).to have_content "Date of last sign in: #{student.course.start_date.to_s}"
  end

  it 'displays no course in refund section if not course present' do
    student.enrollments.delete_all
    visit student_payments_path(student)
    section = all(:css, '.refund-form-info').first
    expect(section).to have_content 'no course'
  end

  it 'displays no attendance records in refund section if none present' do
    visit student_payments_path(student)
    section = all(:css, '.refund-form-info').first
    expect(section).to have_content 'Date of last sign in: no attendance records'
  end

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

  scenario 'does not change cohort' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 60.18
    fill_in "refund-date-#{payment.id}-input", with: Date.today
    click_on 'Refund'
    expect(payment.reload.cohort).to eq payment.cohort
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

  scenario 'unsuccessfully with refund date after cohort end' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 100
    fill_in "refund-date-#{payment.id}-input", with: student.cohort.end_date + 1.week
    click_on 'Refund'
    expect(page).to have_content 'Please correct these problems'
  end

  scenario 'updates refund date if before cohort start' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 100
    fill_in "refund-date-#{payment.id}-input", with: student.cohort.start_date - 1.week
    click_on 'Refund'
    expect(student.payments.last.refund_date).to eq student.cohort.start_date
  end

  scenario 'shows warning if starting cohort does not match current cohort' do
    student.cohort = FactoryBot.create(:pt_intro_cohort)
    student.save
    visit student_payments_path(student)
    expect(page).to have_content 'Starting Cohort does not match Current Cohort'
  end
end

feature 'make a manual stripe payment', :stripe_mock, :stub_mailgun do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card, email: 'example@example.com') }

  before { login_as(admin, scope: :admin) }

  it 'is unavailable with no cohort or pt cohort' do
    unenrolled_student = FactoryBot.create(:student)
    visit student_payments_path(unenrolled_student)
    expect(page).to have_content 'Payments can not be made when cohort is blank.'
  end

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

  scenario 'sets selected cohort', :vcr do
    visit student_payments_path(student)
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: 1765
      select student.cohort.description, from: 'payment_cohort_id'
    end
    click_on 'Stripe payment'
    expect(student.payments.last.cohort).to eq student.cohort
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
      fill_in 'payment_amount', with: 21100
    end
    click_on 'Stripe payment'
    expect(page).to have_content 'Amount is invalid.'
  end

  scenario 'with an invalid amount (negative)' do
    visit student_payments_path(student)
    within '#stripe-payment-form' do
      fill_in 'payment_amount', with: -100
    end
    click_on 'Stripe payment'
    expect(page).to have_content 'Amount is invalid.'
  end

  scenario 'with no primary payment method selected' do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed)
    visit student_payments_path(student)
    expect(page).to have_content 'No primary payment method has been selected'
  end

  scenario 'successfully with mismatching Epicenter and Close.io emails', :vcr do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card, email: 'wrong_email@test.com')
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
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card) }

  before { login_as(admin, scope: :admin) }

  it 'is unavailable with no cohort or pt cohort' do
    unenrolled_student = FactoryBot.create(:student)
    visit student_payments_path(unenrolled_student)
    expect(page).to have_content 'Payments can not be made when cohort is blank.'
  end

  scenario 'successfully with cents' do
    visit student_payments_path(student)
    click_on 'Offline Payment'
    fill_in 'Notes', with: 'Test offline payment'
    within '#offline-payment-form' do
      fill_in 'payment_amount', with: 60.18
    end
    click_on 'Offline payment'
    accept_js_alert
    expect(page).to have_content "Manual payment successfully made for #{student.name}."
    expect(page).to have_content 'Offline'
    expect(page).to have_content '$60.18'
  end

  scenario 'sets selected cohort' do
    visit student_payments_path(student)
    click_on 'Offline Payment'
    fill_in 'Notes', with: 'Test offline payment'
    within '#offline-payment-form' do
      fill_in 'payment_amount', with: 60.18
      select student.cohort.description, from: 'payment_cohort_id'
    end
    click_on 'Offline payment'
    accept_js_alert
    sleep 1
    expect(student.payments.last.cohort).to eq student.cohort
  end
end

feature "Responds to callback from Zapier with qbo txnIDs", :js do
  scenario "and instantiates PaymentCallback model" do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student)
    host = Capybara.current_session.server.host
    port = Capybara.current_session.server.port
    payload = { 'paymentId': payment.id.to_s, 'txnID': '42'}
    RestClient.post("#{host}:#{port}/payment_callbacks", payload.to_json, {content_type: :json, accept: :json})
    expect(payment.reload.qbo_journal_entry_ids).to eq ['42']
  end
end

feature 'make a cost adjustment' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card) }

  context 'as a student' do
    before { login_as(student, scope: :student) }

    it 'does not allow student to view or set tuition adjustment' do
      visit student_payments_path(student)
      expect(page).to_not have_content 'Tuition adjustments'
      expect(page).to_not have_content 'Adjust student tuition'
      expect(page).to_not have_content 'Update upfront tuition total'
    end
  end

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    it 'shows correct info in tuition adjustment info area with no tuition adjustment or payment' do
      student.plan.update(upfront_amount: 8700_00)
      student.update(upfront_amount: nil)
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      expect(page).to have_content "Default upfront amount (based on plan): $8,700.00"
      expect(page).to have_content "No adjustments made to upfront amount."
      expect(page).to have_content "Total paid by student (bank/debit/credit): $0.00"
      expect(page).to have_content "Total paid by third parties (offline): $0.00"
      expect(page).to have_content "Remaining upfront payment owed by student: $8,700.00"
    end

    it 'shows correct info in tuition adjustment info area with adjusted upfront amount and partial payment' do
      student.plan.update(upfront_amount: 8700_00)
      student.update(upfront_amount: 5000_00)
      FactoryBot.create(:payment_with_credit_card, amount: 1000_00, student: student)
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      expect(page).to have_content "Default upfront amount (based on plan): $8,700.00"
      expect(page).to have_content "Current upfront amount (as adjusted): $5,000.00"
      expect(page).to have_content "Total paid by student (bank/debit/credit): $1,000.00"
      expect(page).to have_content "Total paid by third parties (offline): $0.00"
      expect(page).to have_content "Remaining upfront payment owed by student: $4,000.00"
    end

    it 'shows correct info in tuition adjustment info area for standard plan' do
      student.update(plan: FactoryBot.create(:standard_plan))
      FactoryBot.create(:payment, amount: 50_00, student: student, offline: true)
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      expect(page).to have_content "Default upfront amount (based on plan): $100.00"
      expect(page).to have_content "No adjustments made to upfront amount."
      expect(page).to have_content "Total paid by student (bank/debit/credit): $0.00"
      expect(page).to have_content "Total paid by third parties (offline): $50.00"
      expect(page).to have_content "Remaining upfront payment owed by student: $50.00"
    end

    it 'shows current upfront amount in adjustment field' do
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      expect(page).to have_field('cost_adjustment_amount', with: student.plan.upfront_amount/100)
      student.update(upfront_amount: 5000_00)
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      expect(page).to have_field('cost_adjustment_amount', with: 5000)
    end

    it 'allows admin to set upfront amount without cents', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      fill_in 'cost_adjustment_amount', with: 5000
      click_button 'Update upfront tuition total'
      accept_js_alert
      expect(page).to have_content "Upfront tuition total for #{student.name} has been updated to $5000. Remaining upfront amount owed is $5000."
      expect(student.reload.upfront_amount).to eq 5000_00
    end

    it 'does not allow admin to set upfront amount with cents', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      fill_in 'cost_adjustment_amount', with: '5000.50'
      click_button 'Update upfront tuition total'
      accept_js_alert
      expect(page).to_not have_content "Upfront tuition total for #{student.name} has been updated to $5000. Remaining upfront amount owed is $5000."
      expect(student.reload.upfront_amount).to eq student.plan.upfront_amount
    end

    it 'does not allow admin to set upfront amount with negative amount', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      fill_in 'cost_adjustment_amount', with: '-100'
      click_button 'Update upfront tuition total'
      accept_js_alert
      expect(page).to_not have_content "Upfront tuition total for #{student.name} has been updated to $5000. Remaining upfront amount owed is $5000."
      expect(student.reload.upfront_amount).to eq student.plan.upfront_amount
    end

    it 'does not allow tuition adjustment with invalid amount', :js do
      visit student_payments_path(student)
      click_on 'Tuition Adjustment'
      fill_in 'cost_adjustment_amount', with: '100.5'
      click_button 'Update upfront tuition total'
      accept_js_alert
      expect(page).to_not have_content "Upfront tuition total for #{student.name} has been updated to $5000. Remaining upfront amount owed is $5000."
      expect(student.reload.upfront_amount).to eq student.plan.upfront_amount
    end
  end

  feature 'change payment plan', :js do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    let(:student) { FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_all_documents_signed, :with_credit_card) }

    context 'as a student' do
      before { login_as(student, scope: :student) }

      it 'does not allow student to change payment plan' do
        visit student_payments_path(student)
        expect(page).to_not have_content 'Change Payment Plan'
      end
    end

    context 'as an admin' do
      before { login_as(admin, scope: :admin) }

      it 'allows changing payment plan' do
        other_plan = FactoryBot.create(:standard_plan, name: 'other plan')
        visit student_payments_path(student)
        click_on 'Change Payment Plan'
        select other_plan.name, from: "student_plan_id"
        click_on 'Change Plan'
        accept_js_alert
        expect(page).to have_content "Payment plan for #{student.name} has been updated. Upfront amount total has been reset."
      end
    end
  end
end
