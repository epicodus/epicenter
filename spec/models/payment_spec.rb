describe Payment do
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  it { should belong_to :student }
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

  describe 'checks refund date' do
    let(:student) { FactoryBot.create(:student_with_credit_card) }

    it 'should not check refund date on stripe payment', :stripe_mock do
      payment = FactoryBot.build(:payment, student: student, payment_method: student.payment_methods.first)
      expect(payment.save).to eq true
    end

    it 'should not check refund date on offline payment' do
      payment = FactoryBot.build(:payment, student: student, offline: true)
      expect(payment.save).to eq true
    end

    it 'should not check refund date if no course', :stripe_mock do
      student.courses = []
      payment = FactoryBot.create(:payment, student: student, payment_method: student.payment_methods.first)
      expect(payment.update(refund_amount: 50, refund_date: Date.today)).to eq true
    end

    it 'should modify refund date if it predates course start', :stripe_mock do
      payment = FactoryBot.create(:payment, student: student, payment_method: student.payment_methods.first)
      payment.update(refund_amount: 50, refund_date: student.course.start_date - 1.day)
      expect(payment.refund_date).to eq student.course.start_date
    end

    it 'should modify refund date if it predates course start for offline payment' do
      payment = FactoryBot.create(:payment, student: student, payment_method: student.payment_methods.first, offline: true)
      payment.update(refund_amount: 50, refund_date: student.course.start_date - 1.day)
      expect(payment.refund_date).to eq student.course.start_date
    end

    it 'should modify refund date for offline refund' do
      payment = FactoryBot.create(:payment, student: student, offline: true, refund_amount: 100, refund_date: student.course.start_date - 1.day )
      expect(payment.refund_date).to eq student.course.start_date
    end

    it 'should modify refund date if within first 5 weeks of courses' do
      payment = FactoryBot.create(:payment, student: student, payment_method: student.payment_methods.first)
      payment.update(refund_amount: 50, refund_date: student.course.start_date + 4.weeks)
      expect(payment.refund_date).to eq student.course.start_date
    end

    it 'should not modify refund date after first 5 weeks of courses', :stripe_mock do
      payment = FactoryBot.create(:payment, student: student, payment_method: student.payment_methods.first)
      payment.update(refund_amount: 50, refund_date: student.course.start_date + 5.weeks)
      expect(payment.refund_date).to_not eq student.course.start_date
    end

    it 'should throw error if refund date after end of last course' do
      payment = FactoryBot.create(:payment, student: student, payment_method: student.payment_methods.first)
      payment.update(refund_amount: 50, refund_date: student.course.end_date + 1.year)
      expect(payment.errors.full_messages.first).to eq 'Refund date cannot be later than end date of last course.'
    end
  end

  describe 'offline payment status', :vcr do
    it 'sets it successfully' do
      student = FactoryBot.create(:student_with_credit_card)
      payment = FactoryBot.create(:payment, student: student, offline: true, payment_method: student.payment_methods.first)
      expect(payment.status).to eq 'offline'
    end
  end

  describe '.order_by_latest scope' do
    it 'orders by created_at, descending', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      payment_one = FactoryBot.create(:payment_with_credit_card, student: student)
      payment_two = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
    end
  end

  describe 'scopes', :vcr, :stripe_mock, :stub_mailgun do
    let(:student) { FactoryBot.create(:student_with_credit_card, email: 'example@example.com') }
    let(:stripe_payment) { FactoryBot.create(:payment_with_credit_card, student: student) }
    let(:offline_payment) { FactoryBot.create(:payment, offline: true, student: student) }

    describe '.without_failed' do
      it "doesn't include failed payments" do
        Payment.update_all(status: 'failed')
        expect(Payment.without_failed).to eq []
      end
    end

    describe '.online' do
      it "includes only stripe payments" do
        expect(Payment.online).to eq [stripe_payment]
      end
    end

    describe '.offline' do
      it "includes only offline payments" do
        expect(Payment.offline).to eq [offline_payment]
      end
    end
  end

  describe "make a payment with a bank account", :vcr, :stub_mailgun do
    it "makes a successful payment" do
      student = FactoryBot.create :student_with_verified_bank_account, email: 'example@example.com'
      FactoryBot.create(:payment_with_bank_account, student: student)
      expect(student.reload.payments).to_not eq []
    end

    it "sets the fee for the payment type" do
      student = FactoryBot.create :student_with_verified_bank_account, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.fee).to eq 0
    end

    it "sets the status for the payment type" do
      student = FactoryBot.create :student_with_verified_bank_account, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.status).to eq "pending"
    end
  end

  describe "make a payment with a credit card", :vcr, :stripe_mock, :stub_mailgun do
    it "makes a successful payment" do
      student = FactoryBot.create :student_with_credit_card, email: 'example@example.com'
      FactoryBot.create(:payment_with_credit_card, student: student)
      expect(student.reload.payments).to_not eq []
    end

    it "sets the fee for the payment type" do
      student = FactoryBot.create :student_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.fee).to eq 3
    end

    it 'unsuccessfully with an amount that is too high' do
      student = FactoryBot.create :student_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.build(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first, amount: 9250_00)
      expect(payment.save).to be false
    end

    it "sets the status for the payment type" do
      student = FactoryBot.create :student_with_credit_card, email: 'example@example.com'
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.status).to eq "succeeded"
    end
  end

  describe '#total_amount' do
    it 'returns payment amount plus fees', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: student)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(payment.total_amount).to be 618_00
    end
  end

  describe 'sets payment category', :stub_mailgun do
    let(:student) { FactoryBot.create :student_with_credit_card, email: 'example@example.com' }

    it 'calculates category on payment' do
      payment = Payment.create(student: student, category: 'tuition', offline: true, amount: 50_00)
      expect(payment.category).to eq 'upfront'
    end

    it 'calculates category when refund' do
      payment = Payment.create(student: student, category: 'tuition', offline: true, amount: 0, refund_amount: 50_00)
      expect(payment.category).to eq 'refund'
    end
  end

  describe '#set_description', :stripe_mock, :stub_mailgun do
    it 'sets stripe charge description for regular full-time' do
      student = FactoryBot.create(:student_with_credit_card)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 6900_00, category: 'upfront')
      expect(payment.description).to eq "#{student.courses.first.start_date.to_s}-#{student.courses.last.end_date.to_s} | #{student.cohort.description}"
    end

    it 'sets stripe charge description for regular part-time' do
      student = FactoryBot.create(:part_time_student_with_credit_card)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 100_00, category: 'part-time')
      expect(payment.description).to eq "#{student.course.start_date.to_s}-#{student.course.end_date.to_s} | #{student.parttime_cohort.description}"
    end

    it 'sets stripe charge descriptions for full-time payment after part-time payment' do
      student = FactoryBot.create(:part_time_student_with_credit_card)
      part_time_cohort = student.parttime_cohort
      part_time_course = student.course
      first_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 100_00, category: 'part-time')
      full_time_cohort = FactoryBot.create(:internship_only_cohort, start_date: student.course.end_date.next_week)
      student.courses << full_time_cohort.courses.first
      second_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 2000_00, category: 'upfront')
      expect(first_payment.description).to eq "#{part_time_course.start_date.to_s}-#{part_time_course.end_date.to_s} | #{part_time_cohort.description}"
      expect(second_payment.description).to eq "#{full_time_cohort.courses.first.start_date.to_s}-#{full_time_cohort.courses.last.end_date.to_s} | #{full_time_cohort.description}"
    end

    it 'sets payment description to keycard when category set that way', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:student_with_credit_card)
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 25_00, category: 'keycard')
      expect(student.payments.first.description).to eq "keycard"
    end

    it 'sets payment description for offline refund' do
      student = FactoryBot.create(:student_with_cohort)
      payment = FactoryBot.create(:payment, student: student, amount: 0, refund_amount: 100_00, offline: true)
      expect(payment.description).to eq "#{student.courses.first.start_date.to_s}-#{student.courses.last.end_date.to_s} | #{student.ending_cohort.description}"
    end

    it 'sets payment description for offline refund when no courses' do
      student = FactoryBot.create(:student_with_cohort)
      student.courses = []
      payment = FactoryBot.create(:payment, student: student, amount: 0, refund_amount: 100_00, offline: true)
      expect(student.payments.first.description).to eq "-#{student.ending_cohort.end_date.to_s} | #{student.ending_cohort.description}"
    end
  end

  describe "#send_payment_receipt" do
    it "emails the student a receipt after successful payment when the student is on the standard tuition plan", :vcr, :stripe_mock do
      standard_plan = FactoryBot.create(:standard_plan)
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com', plan: standard_plan, referral_email_sent: true)

      allow(EmailJob).to receive(:perform_later).and_return({})
      allow(student).to receive(:total_paid).and_return(100_00)

      FactoryBot.create(:payment_with_credit_card, student: student, amount: standard_plan.upfront_amount)

      expect(EmailJob).to have_received(:perform_later).with(
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $103.00 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the #{standard_plan.name} plan and that you will be required to pay the remaining #{number_to_currency(student.total_remaining_owed / 100, precision: 0)} before the end of the fifth week of class. Please let us know immediately if this is not correct. Thanks so much!" }
      )
    end

    it "emails the student a receipt after successful payment when the student is on the loan plan", :vcr, :stripe_mock do
      loan_plan = FactoryBot.create(:loan_plan)
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com', plan: loan_plan)

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
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')

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
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')

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
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, failure_notice_sent: true)

      expect(EmailJob).to_not receive(:perform_later)
      payment.update(status: 'failed')
    end
  end

  describe 'updating Close.io when a payment is made', :stub_mailgun, :dont_stub_crm, :vcr do
    let(:student) { FactoryBot.create :student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com' }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { get_lead_id(student.email) }

    before do
      allow(CrmUpdateJob).to receive(:perform_later).and_return({})
    end

    context 'lead status is Applicant - Accepted' do
      before do
        allow_any_instance_of(CrmLead).to receive(:status).and_return("Applicant - Accepted")
      end

      it 'updates status and amount paid' do
        payment = Payment.new(student: student, amount: 270_00, payment_method: student.primary_payment_method, category: 'standard')
        expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { status: "Enrolled", 'custom.Amount paid': payment.amount / 100 })
        payment.save
      end

      it 'updates status for part-time students and amount paid' do
        part_time_student = FactoryBot.create(:part_time_student_with_credit_card, email: 'example-part-time@example.com')
        part_time_lead_id = close_io_client.list_leads('email: "' + part_time_student.email + '"')['data'].first['id']
        allow_any_instance_of(CrmLead).to receive(:status).and_return("Applicant - Accepted")
        payment = Payment.new(student: part_time_student, amount: 270_00, payment_method: part_time_student.primary_payment_method, category: 'upfront')
        expect(CrmUpdateJob).to receive(:perform_later).with(part_time_lead_id, { status: "Enrolled - Part-Time", 'custom.Amount paid': payment.amount / 100 })
        payment.save
      end
    end

    context 'lead status is not Applicant - Accepted' do
      before do
        allow_any_instance_of(CrmLead).to receive(:status).and_return("Enrolled")
      end

      it 'only updates amount paid' do
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
  end

  describe 'issuing a refund', :vcr, :stub_mailgun do
    it 'refunds an offline payment without talking to Stripe or Mailgun', :stripe_mock do
      student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card)
      payment = FactoryBot.create(:payment_with_credit_card, student: student, offline: true)
      payment.update(refund_amount: 51)
      expect(payment.refund_amount).to eq 51
      expect(payment).to_not receive(:issue_refund)
      expect(payment).to_not receive(:send_refund_receipt)
    end

    it 'refunds a credit card payment' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      payment.update(refund_amount: 51, refund_date: Date.today)
      expect(payment.refund_amount).to eq 51
    end

    it 'fails to refund a credit card payment when the refund amount is more than the payment amount' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.update(refund_amount: 200, refund_date: Date.today)).to eq false
    end

    it 'fails to refund a credit card payment when the refund amount is negative' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student)
      expect(payment.update(refund_amount: -37, refund_date: Date.today)).to eq false
    end

    it 'refunds a bank account payment' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      payment.update(refund_amount: 75, refund_date: Date.today)
      expect(payment.refund_amount).to eq 75
    end

    it 'fails to refund a bank account payment when the refund amount is more than the payment amount' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.update(refund_amount: 200, refund_date: Date.today)).to eq false
    end

    it 'fails to refund a bank account payment when the refund amount is negative' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment.update(refund_amount: -40, refund_date: Date.today)).to eq false
    end

    it 'issues refund' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      expect(payment).to receive(:issue_refund)
      payment.update(refund_amount: 50, refund_date: Date.today)
    end

    it 'does not issue refund if already issued' do
      student = FactoryBot.create(:student_with_all_documents_signed_and_verified_bank_account, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_bank_account, student: student)
      payment.update(refund_amount: 50, refund_date: Date.today)
      expect(payment).to_not receive(:issue_refund)
      payment.update(status: "successful")
    end
  end

  describe "#send_refund_receipt" do
    it "emails the student a receipt after successful refund", :vcr do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')

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
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')

      allow(EmailJob).to receive(:perform_later).and_return({})

      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_issued: true)

      expect(EmailJob).to_not receive(:perform_later)
      payment.update(refund_amount: 50_00, refund_date: Date.today)
    end
  end

  describe "sends webhook after successful payment creation", :dont_stub_webhook do
    before { allow(WebhookJob).to receive(:perform_later).and_return({}) }

    it 'does not post webhook for keycard payment', :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 25_00, category: 'keycard')
      expect(WebhookJob).not_to have_received(:perform_later)
    end

    it 'posts webhook for a successful stripe payment', :stripe_mock, :stub_mailgun do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(WebhookJob).to have_received(:perform_later).with({ method: nil, endpoint: ENV['ZAPIER_PAYMENT_WEBHOOK_URL'], payload: PaymentSerializer.new(payment).as_json.merge({ event_name: 'payment' }) })
    end

    it 'posts webhook after refund issued', :stub_mailgun do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(WebhookJob).to receive(:perform_later).with({ method: nil, endpoint: ENV['ZAPIER_PAYMENT_WEBHOOK_URL'], payload: PaymentSerializer.new(payment).as_json.merge({ event_name: 'refund', refund_amount: 500, start_date: student.course.start_date.to_s }) })
      payment.update(refund_amount: 500, refund_date: student.course.start_date)
    end

    it 'posts webhook for an offline payment', :vcr do
      student = FactoryBot.create(:student_with_cohort, email: 'example@example.com')
      payment = FactoryBot.create(:payment, student: student, amount: 600_00, offline: true)
      expect(WebhookJob).to have_received(:perform_later).with({ method: nil, endpoint: ENV['ZAPIER_PAYMENT_WEBHOOK_URL'], payload: PaymentSerializer.new(payment).as_json.merge({ event_name: 'payment_offline' }) })
    end

    it 'posts webhook for an offline refund', :vcr do
      student = FactoryBot.create(:student_with_cohort, email: 'example@example.com')
      payment = FactoryBot.create(:payment, student: student, amount: 0, refund_amount: 600_00, offline: true)
      expect(WebhookJob).to have_received(:perform_later).with({ method: nil, endpoint: ENV['ZAPIER_PAYMENT_WEBHOOK_URL'], payload: PaymentSerializer.new(payment).as_json.merge({ event_name: 'refund_offline' }) })
    end
  end
end
