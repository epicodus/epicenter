describe Payment do
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

  describe "#send_payment_receipt" do
    it "emails the student a receipt after successful payment", :vcr, :stripe_mock do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 600_00)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :bcc => ENV['FROM_EMAIL_PAYMENT'],
          :subject => "Epicodus tuition payment receipt",
          :text => "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
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
end
