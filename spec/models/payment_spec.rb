describe Payment do
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  it { should belong_to :student }
  it { should belong_to :payment_method }
  it { should validate_presence_of :student_id }
  it { should validate_presence_of :amount }

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

  describe 'offline payment status' do
    it 'sets it successfully' do
      student = FactoryGirl.create(:student)
      payment = FactoryGirl.create(:payment, student: student, offline: true)
      expect(payment.status).to eq 'offline'
    end
  end

  describe '.order_by_latest scope' do
    it 'orders by created_at, descending', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      payment_one = FactoryGirl.create(:payment_with_credit_card, student: student)
      payment_two = FactoryGirl.create(:payment_with_credit_card, student: student)
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
    end
  end

  describe '.without_failed' do
    it "doesn't include failed payments", :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      failed_payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      failed_payment.update(status: 'failed')
      expect(Payment.without_failed).to eq []
    end
  end

  describe "make a payment with a bank account", :vcr, :stub_mailgun do
    it "makes a successful payment" do
      student = FactoryGirl.create :user_with_verified_bank_account, email: 'test@test.com'
      FactoryGirl.create(:payment_with_bank_account, student: student)
      student.reload
      expect(student.payments).to_not eq []
    end

    it "sets the fee for the payment type" do
      student = FactoryGirl.create :user_with_verified_bank_account, email: 'test@test.com'
      payment = FactoryGirl.create(:payment_with_bank_account, student: student)
      expect(payment.fee).to eq 0
    end

    it "sets the status for the payment type" do
      student = FactoryGirl.create :user_with_verified_bank_account, email: 'test@test.com'
      payment = FactoryGirl.create(:payment_with_bank_account, student: student)
      expect(payment.status).to eq "pending"
    end
  end

  describe "make a payment with a credit card", :vcr, :stripe_mock, :stub_mailgun do
    it "makes a successful payment" do
      student = FactoryGirl.create :user_with_credit_card, email: 'test@test.com'
      FactoryGirl.create(:payment_with_credit_card, student: student)
      student.reload
      expect(student.payments).to_not eq []
    end

    it "sets the fee for the payment type" do
      student = FactoryGirl.create :user_with_credit_card, email: 'test@test.com'
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      expect(payment.fee).to eq 32
    end

    it 'unsuccessfully with an amount that is too high' do
      student = FactoryGirl.create :user_with_credit_card, email: 'test@test.com'
      payment = FactoryGirl.build(:payment_with_credit_card, student: student, amount: 5250_00)
      expect(payment.save).to be false
    end

    it "sets the status for the payment type" do
      student = FactoryGirl.create :user_with_credit_card, email: 'test@test.com'
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      expect(payment.status).to eq "succeeded"
    end
  end

  describe '#total_amount' do
    it 'returns payment amount plus fees', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      FactoryGirl.create(:payment_with_credit_card, student: student)
      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(payment.total_amount).to be 618_21
    end
  end

  describe '#set_description' do
    it 'sets stripe charge description for regular full-time', :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(payment.description).to eq "#{student.courses.first.office.name}; #{student.courses.first.start_date.strftime("%Y-%m-%d")}; Full-time"
    end

    it 'sets stripe charge description for regular part-time', :vcr, :stripe_mock, :stub_mailgun do
      part_time_course = FactoryGirl.create(:part_time_course, description: "Intro Evening")
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com', course: part_time_course)
      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(payment.description).to eq "#{part_time_course.office.name}; #{part_time_course.start_date.strftime("%Y-%m-%d")}; Part-time"
    end

    it 'sets stripe charge descriptions for full-time payment after part-time payment', :vcr, :stripe_mock, :stub_mailgun do
      part_time_course = FactoryGirl.create(:part_time_course, description: "Intro Evening")
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com', course: part_time_course)
      first_payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      full_time_course = FactoryGirl.create(:course)
      student.courses.push(full_time_course)
      second_payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      expect(first_payment.description).to eq "#{part_time_course.office.name}; #{part_time_course.start_date.strftime("%Y-%m-%d")}; Part-time"
      expect(second_payment.description).to eq "#{full_time_course.office.name}; #{full_time_course.start_date.strftime("%Y-%m-%d")}; Full-time"
    end
  end

  describe "#send_payment_receipt" do
    it "emails the student a receipt after successful payment when the student is on the standard tuition plan", :vcr, :stripe_mock do
      standard_plan = FactoryGirl.create(:standard_plan)
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com', plan: standard_plan, referral_email_sent: true)

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the Standard tuition plan and that we will be charging you the remaining #{number_to_currency(standard_plan.first_day_amount / 100, precision: 0)} on the first day of class. I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!" }
      )
    end

    it "emails the student a receipt after successful payment when the student is on the loan plan", :vcr, :stripe_mock do
      loan_plan = FactoryGirl.create(:loan_plan)
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com', plan: loan_plan)

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. I am going over the payments for your class and just wanted to confirm that you have chosen the Loan plan. Since you are in the process of obtaining a loan for program tuition, would you please let me know (which loan company, date you applied, etc.)? I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!" }
      )
    end

    it "emails the student a receipt after successful payment when the student is on the upfront plan", :vcr, :stripe_mock do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      FactoryGirl.create(:payment_with_credit_card, student: student)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition payment receipt",
          text: "Hi #{student.name}. This is to confirm your payment of $1.32 for Epicodus tuition. Thanks so much!" }
      )
    end
  end

  describe "failed" do
    it "emails the student a failure notice if payment status is updated to 'failed'", :vcr, :stripe_mock do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      payment.update(status: 'failed')

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus payment failure notice",
          :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
      )
    end
  end

  describe 'updating Close.io when a payment is made' do
    let(:student) { FactoryGirl.create :user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com' }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { close_io_client.list_leads('email:' + student.email).data.first.id }

    before do
      allow(student).to receive(:close_io_client).and_return(close_io_client)
    end

    it 'updates status and amount paid on the first payment', :vcr, :stub_mailgun do
      payment = Payment.new(student: student, amount: 270_00, payment_method: student.primary_payment_method)
      expect(student).to receive(:update_close_io).with({ status: "Enrolled", 'custom.Amount paid': payment.amount / 100 })
      payment.save
    end

    it 'only updates amount paid on payments beyond the first', :vcr, :stub_mailgun do
      payment = Payment.create(student: student, amount: 100_00, payment_method: student.primary_payment_method)
      payment_2 = Payment.new(student: student, amount: 50_00, payment_method: student.primary_payment_method)
      expect(student).to receive(:update_close_io).with({ 'custom.Amount paid': (payment.amount + payment_2.amount) / 100 })
      payment_2.save
    end
  end

  describe 'issuing a refund', :vcr, :stub_mailgun do
    it 'refunds an offline payment without talking to Stripe or Mailgun', :stripe_mock do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card)
      payment = FactoryGirl.create(:payment_with_credit_card, student: student, offline: true)
      payment.update(refund_amount: 51)
      expect(payment.refund_amount).to eq 51
      expect(payment).to_not receive(:issue_refund)
      expect(payment).to_not receive(:send_refund_receipt)
    end

    it 'refunds a credit card payment' do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      payment.update(refund_amount: 51)
      expect(payment.refund_amount).to eq 51
    end

    it 'fails to refund a credit card payment when the refund amount is more than the payment amount' do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      expect(payment.update(refund_amount: 200)).to eq false
    end

    it 'fails to refund a credit card payment when the refund amount is negative' do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      expect(payment.update(refund_amount: -37)).to eq false
    end

    it 'refunds a bank account payment' do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_bank_account, student: student)
      payment.update(refund_amount: 75)
      expect(payment.refund_amount).to eq 75
    end

    it 'fails to refund a bank account payment when the refund amount is more than the payment amount' do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_bank_account, student: student)
      expect(payment.update(refund_amount: 200)).to eq false
    end

    it 'fails to refund a bank account payment when the refund amount is negative' do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_bank_account, student: student)
      expect(payment.update(refund_amount: -40)).to eq false
    end

    it 'does not update Close.io', :vcr, :stub_mailgun do
      student = FactoryGirl.create :user_with_all_documents_signed_and_credit_card, email: 'test@test.com'
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      payment.update(refund_amount: 51)
      expect(student).to_not receive(:update_close_io)
    end
  end

  describe "#send_refund_receipt" do
    it "emails the student a receipt after successful refund", :vcr do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)
      payment.update(refund_amount: 50_00)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus tuition refund receipt",
          :text => "Hi #{student.name}. This is to confirm your refund of $50.00 from your Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
      )
    end
  end

  describe '#send_referral_email', :stripe_mock, :vcr do
    let(:student) { FactoryGirl.create(:user_with_credit_card, email: 'test@test.com') }

    it 'does not email the student a referral email for an offline payment' do
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      FactoryGirl.create(:payment_with_credit_card, student: student, offline: true)

      expect(mailgun_client).to_not have_received(:send_message).with(
        "epicodus.com",
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition discount",
          text: "Hi #{student.name}! We hope you're as excited to start your time at Epicodus as we are to have you. Many of our students learn about Epicodus from their friends, and we always like to thank people for spreading the word. If you mention Epicodus to someone you know and they enroll, we'll take $100 off both of your tuition. Just tell your friend to mention that you referred them in their interview." }
      )
      expect(student.referral_email_sent).to eq nil
    end

    it 'emails the student a referral email when the first tuition payment is made' do
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      FactoryGirl.create(:payment_with_credit_card, student: student)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition discount",
          text: "Hi #{student.name}! We hope you're as excited to start your time at Epicodus as we are to have you. Many of our students learn about Epicodus from their friends, and we always like to thank people for spreading the word. If you mention Epicodus to someone you know and they enroll, we'll take $100 off both of your tuition. Just tell your friend to mention that you referred them in their interview." }
      )
      expect(student.referral_email_sent).to eq true
    end

    it 'does not email the student a referral email if one has already been sent' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com', referral_email_sent: true)
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      FactoryGirl.create(:payment_with_credit_card, student: student)

      expect(mailgun_client).to_not have_received(:send_message).with(
        "epicodus.com",
        { from: ENV['FROM_EMAIL_PAYMENT'],
          to: student.email,
          bcc: ENV['FROM_EMAIL_PAYMENT'],
          subject: "Epicodus tuition discount",
          text: "Hi #{student.name}! We hope you're as excited to start your time at Epicodus as we are to have you. Many of our students learn about Epicodus from their friends, and we always like to thank people for spreading the word. If you mention Epicodus to someone you know and they enroll, we'll take $100 off both of your tuition. Just tell your friend to mention that you referred them in their interview." }
      )
    end
  end
end
