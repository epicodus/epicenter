describe Payment do
  it { should belong_to :student }
  it { should belong_to :payment_method }
  it { should validate_presence_of :student_id }
  it { should validate_presence_of :payment_method }
  it { should validate_presence_of :amount }

  describe '.order_by_latest scope' do
    it 'orders by created_at, descending', :vcr do
      StripeMock.create_test_helper
      StripeMock.start
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      payment_one = FactoryGirl.create(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first)
      payment_two = FactoryGirl.create(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first)
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
      StripeMock.stop
    end
  end

  describe '.without_failed' do
    it "doesn't include failed payments", :vcr do
      StripeMock.create_test_helper
      StripeMock.start
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      failed_payment = FactoryGirl.create(:payment_with_credit_card, student: student, payment_method: student.payment_methods.first)
      failed_payment.update(status: 'failed')
      expect(Payment.without_failed).to eq []
      StripeMock.stop
    end
  end

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      student = FactoryGirl.create :user_with_verified_bank_account, email: 'test@test.com'
      student.payments.create(amount: 100, payment_method: student.bank_accounts.first)
      student.reload
      expect(student.payments).to_not eq []
    end

    it "sets the fee for the payment type", :vcr do
      student = FactoryGirl.create :user_with_verified_bank_account, email: 'test@test.com'
      payment = student.payments.create(amount: 100, payment_method: student.bank_accounts.first)
      expect(payment.fee).to eq 0
    end

    it "sets the status for the payment type", :vcr do
      student = FactoryGirl.create :user_with_verified_bank_account, email: 'test@test.com'
      payment = student.payments.create(amount: 100, payment_method: student.bank_accounts.first)
      expect(payment.status).to eq "pending"
    end
  end

  describe '#check_if_paid_up' do
    it 'does nothing if student is not paid up', :vcr do
      student = FactoryGirl.create(:user_with_recurring_active, email: 'test@test.com')
      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)
      expect(student.recurring_active).to be true
    end

    it 'sets recurring_active to false if student is paid up', :vcr do
      StripeMock.create_test_helper
      StripeMock.start
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, total_amount: 5000_00)
      student = FactoryGirl.create(:user_with_credit_card, plan: plan, email: 'test@test.com')
      payment = student.payments.create(amount: 5000_00, payment_method: student.credit_cards.first)
      expect(student.recurring_active).to be false
      StripeMock.stop
    end
  end

  describe '#total_amount' do
    it 'returns payment amount plus fees', :vcr do
      StripeMock.create_test_helper
      StripeMock.start
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)
      expect(payment.total_amount).to be 618_21
      StripeMock.stop
    end
  end

  describe "#send_payment_receipt" do
    it "emails the student a receipt after successful payment", :vcr do
      StripeMock.create_test_helper
      StripeMock.start
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus tuition payment receipt",
          :text => "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
      )
      StripeMock.stop
    end
  end

  describe "failed" do
    it "emails the student a failure notice if payment status is updated to 'failed'", :vcr do
      StripeMock.create_test_helper
      StripeMock.start
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)
      payment.update(status: 'failed')

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus payment failure notice",
          :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
      )
      StripeMock.stop
    end

    it "switches their recurring active status to false", :vcr do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      student.update(recurring_active: true)
      payment = FactoryGirl.create(:payment, student: student)
      payment.update(status: 'failed')
      expect(student.recurring_active?).to be false
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
end
