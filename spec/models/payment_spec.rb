describe Payment do
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  it { should belong_to :student }
  it { should belong_to :payment_method }
  it { should validate_presence_of :student_id }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :category }

  before do
    allow_any_instance_of(CrmLead).to receive(:status)
  end

  describe 'validations' do
    context 'if regular payment' do
      before { allow(subject).to receive(:offline?).and_return(false) }
      it { should validate_presence_of :payment_method }
    end

    context 'if offline payment' do
      before { allow(subject).to receive(:offline?).and_return(true) }
      it { should_not validate_presence_of :payment_method }
    end
  end

  describe 'offline payment status', :vcr do
    it 'sets it successfully' do
      student = FactoryBot.create(:user_with_credit_card)
      payment = FactoryBot.create(:payment, student: student, offline: true, payment_method: student.payment_methods.first)
      expect(payment.status).to eq 'offline'
    end
  end

  describe '.order_by_latest scope' do
    it 'orders by created_at, descending', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      payment_one = FactoryBot.create(:payment_with_credit_card, student: student)
      payment_two = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
    end
  end

  describe '.without_failed' do
    it "doesn't include failed payments", :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      failed_payment = FactoryBot.create(:payment_with_credit_card, student: student)
      failed_payment.update(status: 'failed')
      expect(Payment.without_failed).to eq []
    end
  end

  describe "make a payment with a bank account", :vcr, :stub_mailgun do
    it "makes a successful payment" do
      student = FactoryBot.create :user_with_verified_bank_account, email: 'example@example.com'
      FactoryBot.create(:payment_with_bank_account, student: student)
      expect(student.reload.payments).to_not eq []
    end

    it "sets the fee for the payment type" do
      student = FactoryBot.create :user_with_verified_bank_account, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.fee).to eq 0
    end

    it "sets the status for the payment type" do
      student = FactoryBot.create :user_with_verified_bank_account, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.status).to eq "pending"
    end
  end

  describe "make a payment with a credit card", :vcr, :stripe_mock, :stub_mailgun do
    it "makes a successful payment" do
      student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
      FactoryBot.create(:payment_with_credit_card, student: student)
      expect(student.reload.payments).to_not eq []
    end

    it "sets the fee for the payment type" do
      student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.fee).to eq 3
    end

    it 'unsuccessfully with an amount that is too high' do
      student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.build(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first, amount: 9250_00)
      expect(payment.save).to be false
    end

    it "sets the status for the payment type" do
      student = FactoryBot.create :user_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.status).to eq "succeeded"
    end
  end

  describe '#total_amount' do
    it 'returns payment amount plus fees', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: student)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(payment.total_amount).to be 618_00
    end
  end

  describe '#calculate_category' do
    let(:student_upfront_plan) { FactoryBot.create :student, email: 'example@example.com' }
    let(:student_standard_plan) { FactoryBot.create :student, email: 'example@example.com', plan: FactoryBot.create(:standard_plan) }

    it 'calculates category when refund, regardless of plan' do
      payment = Payment.new(student: student_upfront_plan, category: 'tuition', offline: true, amount: 0, refund_amount: 50_00)
      expect(payment.calculate_category).to eq 'refund'
    end

    it 'calculates category when refund, regardless of plan' do
      payment = Payment.new(student: student_standard_plan, category: 'tuition', offline: true, amount: 0, refund_amount: 50_00)
      expect(payment.calculate_category).to eq 'refund'
    end

    it 'calculates category when upfront payment' do
      payment = Payment.new(student: student_upfront_plan, category: 'tuition', offline: true, amount: 50_00)
      expect(payment.calculate_category).to eq 'upfront'
    end

    it 'calculates category when second payment on plan other than standard' do
      payment = Payment.create(student: student_upfront_plan, category: 'tuition', offline: true, amount: 100_00)
      payment2 = Payment.new(student: student_upfront_plan, category: 'tuition', offline: true, amount: 4700_00)
      expect(payment2.calculate_category).to eq 'upfront'
    end

    it 'calculates category when first payment on standard plan' do
      payment = Payment.new(student: student_upfront_plan, category: 'tuition', offline: true, amount: 4700_00)
      expect(payment.calculate_category).to eq 'upfront'
    end

    it 'calculates category when second payment on legacy standard plan' do
      legacy_student = FactoryBot.create(:student, plan: FactoryBot.create(:standard_plan_legacy))
      payment = Payment.create(student: legacy_student, category: 'tuition', offline: true, amount: 100_00)
      payment2 = Payment.new(student: legacy_student, category: 'tuition', offline: true, amount: 4700_00)
      expect(payment2.calculate_category).to eq 'standard'
    end

    it 'calculates category when second payment on new standard plan' do
      payment = Payment.create(student: student_standard_plan, category: 'tuition', offline: true, amount: 100_00)
      payment2 = Payment.new(student: student_standard_plan, category: 'tuition', offline: true, amount: 4700_00)
      expect(payment2.calculate_category).to eq 'upfront'
    end

    it 'raises error when no payment plan' do
      student = FactoryBot.create(:student, plan: nil)
      payment = Payment.new(student: student, category: 'tuition', offline: true, amount: 100_00)
      expect(payment.save).to eq false
    end
  end

  describe '#set_description', :stripe_mock, :stub_mailgun do
    it 'sets stripe charge description for regular full-time' do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'upfront')
      expect(payment.description).to eq "#{student.courses.first.office.name}; #{student.courses.first.start_date.strftime("%Y-%m-%d")}; Full-time; #{payment.category}"
    end

    it 'sets stripe charge description for regular part-time' do
      FactoryBot.create(:parttime_plan)
      part_time_course = FactoryBot.create(:part_time_course)
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', course: part_time_course)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'part-time')
      expect(payment.description).to eq "#{part_time_course.office.name}; #{part_time_course.start_date.strftime("%Y-%m-%d")}; Part-time; #{payment.category}"
    end

    it 'sets stripe charge descriptions for full-time payment after part-time payment' do
      FactoryBot.create(:parttime_plan)
      part_time_course = FactoryBot.create(:part_time_course)
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', course: part_time_course)
      first_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'part-time')
      full_time_course = FactoryBot.create(:course)
      student.courses.push(full_time_course)
      second_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, category: 'upfront')
      expect(first_payment.description).to eq "#{part_time_course.office.name}; #{part_time_course.start_date.strftime("%Y-%m-%d")}; Part-time; #{first_payment.category}"
      expect(second_payment.description).to eq "#{full_time_course.office.name}; #{full_time_course.start_date.strftime("%Y-%m-%d")}; Full-time conversion; #{second_payment.category}"
    end

    it 'sets payment description when student not enrolled in any course but known office', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      student.courses.delete_all
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(student.payments.first.description).to eq "#{student.office.name}; no enrollments; no enrollments; #{payment.category}"
    end

    it 'sets payment description to include student email if payment made for student not enrolled in any course and no office', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', office: nil)
      student.courses.delete_all
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(student.payments.first.description).to eq "special: #{student.email} not enrolled in any courses and unknown office"
    end

    it 'sets payment description to keycard when category set that way', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 25_00, category: 'keycard')
      expect(student.payments.first.description).to eq "keycard"
    end

    it 'updates student office when nil but enrolled in courses', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', office: nil)
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(student.office).to eq student.course.office
    end
  end

  describe "#send_payment_receipt" do
    it "emails the student a receipt after successful payment when the student is on the standard tuition plan", :vcr, :stripe_mock do
      standard_plan = FactoryBot.create(:standard_plan)
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', plan: standard_plan, referral_email_sent: true)

      allow(EmailJob).to receive(:perform_later).and_return({})

      FactoryBot.create(:payment_with_credit_card, student: student, amount: standard_plan.upfront_amount)

      expect(EmailJob).to have_received(:perform_later).with(
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $103.00 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the #{standard_plan.name} plan and that you will be required to pay the remaining #{number_to_currency(standard_plan.student_portion / 100, precision: 0)} before the end of the fifth week of class. Please let us know immediately if this is not correct. Thanks so much!" }
      )
    end

    it "emails the student a receipt after successful payment when the student is on the loan plan", :vcr, :stripe_mock do
      loan_plan = FactoryBot.create(:loan_plan)
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com', plan: loan_plan)

      allow(EmailJob).to receive(:perform_later).and_return({})

      FactoryBot.create(:payment_with_credit_card, student: student, amount: loan_plan.upfront_amount)

      expect(EmailJob).to have_received(:perform_later).with(
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $103.00 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the #{loan_plan.name} plan. Since you are in the process of obtaining a loan for program tuition, would you please let me know (which loan company, date you applied, etc.)? Thanks so much!" }
      )
    end

    it "emails the student a receipt after successful payment when the student is on the upfront plan", :vcr, :stripe_mock do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      FactoryBot.create(:payment_with_credit_card, student: student, amount: student.plan.upfront_amount)
      FactoryBot.create(:payment_with_credit_card, student: student)

      expect(EmailJob).to have_received(:perform_later).with(
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $7,107.00 for Epicodus tuition. Thanks so much!" }
      )
    end
  end

  describe "failed" do
    it "emails the student a failure notice if payment status is updated to 'failed'", :vcr, :stripe_mock do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      payment.update(status: 'failed')

      expect(EmailJob).to have_received(:perform_later).with(
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus payment failure notice",
          :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
      )
    end

    it "does not email the student a failure notice twice for the same payment", :vcr, :stripe_mock do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, failure_notice_sent: true)

      expect(EmailJob).to_not receive(:perform_later)
      payment.update(status: 'failed')
    end
  end

  describe 'updating Close.io when a payment is made', :stub_mailgun, :dont_stub_crm, :vcr do
    let(:student) { FactoryBot.create :user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com' }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { get_lead_id(student.email) }

    before do
      allow(CrmUpdateJob).to receive(:perform_later).and_return({})
    end

    it 'updates status and amount paid on the first payment' do
      allow_any_instance_of(CrmLead).to receive(:status).and_return("Applicant - Accepted")
      payment = Payment.new(student: student, amount: 270_00, payment_method: student.primary_payment_method, category: 'standard')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { status: "Enrolled", 'custom.Amount paid': payment.amount / 100 })
      payment.save
    end

    it 'updates status for part-time students and amount paid on the first payment' do
      FactoryBot.create(:parttime_plan)
      part_time_student = FactoryBot.create(:part_time_student_with_payment_method, email: 'example-part-time@example.com')
      part_time_lead_id = close_io_client.list_leads('email: "' + part_time_student.email + '"')['data'].first['id']
      allow_any_instance_of(CrmLead).to receive(:status).and_return("Applicant - Accepted")
      payment = Payment.new(student: part_time_student, amount: 270_00, payment_method: part_time_student.primary_payment_method, category: 'upfront')
      expect(CrmUpdateJob).to receive(:perform_later).with(part_time_lead_id, { status: "Enrolled - Part-Time", 'custom.Amount paid': payment.amount / 100 })
      payment.save
    end

    it 'only updates amount paid on payments beyond the first' do
      payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
      payment_2 = Payment.new(student: student, amount: 50_00, payment_method: student.primary_payment_method, category: 'standard')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { 'custom.Amount paid': (payment.amount + payment_2.amount) / 100 })
      payment_2.save
    end

    it 'updates amount paid for offline payments' do
      payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
      payment_2 = Payment.new(student: student, amount: 50_00, category: 'standard', offline: true)
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { 'custom.Amount paid': (payment.amount + payment_2.amount) / 100 })
      payment_2.save
    end

    it 'updates amount paid for refunds' do
      payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
      payment_2 = Payment.new(student: student, amount: 50_00, category: 'standard', offline: true)
      payment_2.update(refund_amount: 5000, refund_date: Date.today)
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { 'custom.Amount paid': (payment.amount + payment_2.amount - payment_2.refund_amount) / 100 })
      payment_2.save
    end

    it 'adds note to CRM' do
      payment = Payment.new(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "PAYMENT #{number_to_currency(payment.amount / 100.00)}: " })
      payment.save
    end

    it 'adds note to CRM including notes when present' do
      payment = Payment.new(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard', notes: 'test payment note from api')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "PAYMENT #{number_to_currency(payment.amount / 100.00)}: #{payment.notes}" })
      payment.save
    end

    it 'adds note to CRM on refund including refund notes' do
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      payment.refund_amount = 50
      payment.refund_notes = 'foo'
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "PAYMENT REFUND #{number_to_currency(payment.refund_amount / 100.00)}: #{payment.refund_notes}" })
      payment.save
    end

    it 'does not add note to CRM on payment update unless refund' do
      payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method, category: 'standard')
      payment.status = "changed"
      expect(CrmUpdateJob).to_not receive(:perform_later).with(lead_id, { note: "PAYMENT #{number_to_currency(payment.amount / 100.00)}: " })
      payment.save
    end
  end

  describe 'issuing a refund', :vcr, :stub_mailgun do
    it 'refunds an offline payment without talking to Stripe or Mailgun', :stripe_mock do
      student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, offline: true)
      payment.update(refund_amount: 51)
      expect(payment.refund_amount).to eq 51
      expect(payment).to_not receive(:issue_refund)
      expect(payment).to_not receive(:send_refund_receipt)
    end

    it 'refunds a credit card payment' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      payment.update(refund_amount: 51, refund_date: Date.today)
      expect(payment.refund_amount).to eq 51
    end

    it 'fails to refund a credit card payment when the refund amount is more than the payment amount' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.update(refund_amount: 200, refund_date: Date.today)).to eq false
    end

    it 'fails to refund a credit card payment when the refund amount is negative' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.update(refund_amount: -37, refund_date: Date.today)).to eq false
    end

    it 'refunds a bank account payment' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      payment.update(refund_amount: 75, refund_date: Date.today)
      expect(payment.refund_amount).to eq 75
    end

    it 'fails to refund a bank account payment when the refund amount is more than the payment amount' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.update(refund_amount: 200, refund_date: Date.today)).to eq false
    end

    it 'fails to refund a bank account payment when the refund amount is negative' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.update(refund_amount: -40, refund_date: Date.today)).to eq false
    end

    it 'issues refund' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment).to receive(:issue_refund)
      payment.update(refund_amount: 50, refund_date: Date.today)
    end

    it 'does not issue refund if already issued' do
      student = FactoryBot.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      payment.update(refund_amount: 50, refund_date: Date.today)
      expect(payment).to_not receive(:issue_refund)
      payment.update(status: "successful")
    end
  end

  describe "#send_refund_receipt" do
    it "emails the student a receipt after successful refund", :vcr do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      payment.update(refund_amount: 5000, refund_date: Date.today)

      expect(EmailJob).to have_received(:perform_later).with(
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus tuition refund receipt",
          :text => "Hi #{student.name}. This is to confirm your refund of $50.00 from your Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
      )
    end

    it "does not send second copy of refund receipt for payment", :vcr do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_issued: true)

      expect(EmailJob).to_not receive(:perform_later)
      payment.update(refund_amount: 50_00, refund_date: Date.today)
    end
  end

  describe "sends webhook after successful payment creation", :dont_stub_webhook do
    before { allow(WebhookJob).to receive(:perform_later).and_return({}) }

    it 'posts webhook for a successful stripe payment', :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(payment).as_json.merge({ event_name: 'payment' }))
    end

    it 'posts webhook after refund issued', :vcr, :stub_mailgun do
      student = FactoryBot.create(:user_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(WebhookJob).to receive(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(payment).as_json.merge({ event_name: 'refund', refund_amount: 500, refund_date: Date.today.to_s }))
      payment.update(refund_amount: 500, refund_date: Date.today)
    end

    it 'posts webhook for an offline payment', :vcr do
      student = FactoryBot.create(:student, email: 'example@example.com')
      payment = FactoryBot.create(:payment, student: student, amount: 600_00, offline: true)
      expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(payment).as_json.merge({ event_name: 'payment_offline' }))
    end

    it 'posts webhook for an offline refund', :vcr do
      student = FactoryBot.create(:student, email: 'example@example.com')
      payment = FactoryBot.create(:payment, student: student, amount: 0, refund_amount: 600_00, offline: true)
      expect(WebhookJob).to have_received(:perform_later).with(ENV['ZAPIER_WEBHOOK_URL'], PaymentSerializer.new(payment).as_json.merge({ event_name: 'refund_offline' }))
    end
  end
end
