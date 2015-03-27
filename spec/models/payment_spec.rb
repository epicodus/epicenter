describe Payment do

  it { should belong_to :student }
  it { should belong_to :payment_method }
  it { should validate_presence_of :student_id }
  it { should validate_presence_of :payment_method }
  it { should validate_presence_of :amount }

  describe '.order_by_latest scope' do
    it 'orders by created_at, descending', :vcr do
      payment_one = FactoryGirl.create(:payment)
      payment_two = FactoryGirl.create(:payment)
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
    end
  end

  describe '.without_failed' do
    it "doesn't include failed payments", :vcr do
      failed_payment = FactoryGirl.create(:payment)
      failed_payment.update(status: 'failed')
      expect(Payment.without_failed).to eq []
    end
  end

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      student = FactoryGirl.create :user_with_verified_bank_account
      student.payments.create(amount: 100, payment_method: student.bank_accounts.first)
      student.reload
      expect(student.payments).to_not eq []
    end

    it "doesn't make a payment with a bad card", :vcr do
      student = FactoryGirl.create :user_with_invalid_credit_card
      student.payments.create(amount: 100, payment_method: student.credit_cards.first)
      student.reload
      expect(student.payments).to eq []
    end
  end

  describe '#check_if_paid_up' do
    it 'does nothing if student is not paid up', :vcr do
      student = FactoryGirl.create(:user_with_recurring_active)
      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)
      expect(student.recurring_active).to be true
    end

    it 'sets recurring_active to false if student is paid up', :vcr do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, total_amount: 5000_00)
      student = FactoryGirl.create(:user_with_credit_card, plan: plan)
      payment = student.payments.create(amount: 5000_00, payment_method: student.credit_cards.first)
      expect(student.recurring_active).to be false
    end
  end

  describe '#ensure_payment_isnt_over_balance' do
    it 'does not save if payment amount exceeds outstanding balance', :vcr do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, total_amount: 5000_00)
      student = FactoryGirl.create(:user_with_credit_card, plan: plan)
      payment = student.payments.new(amount: 5100_00, payment_method: student.credit_cards.first)
      expect(payment.valid?).to be false
      expect(payment.errors.messages[:amount]).to include('exceeds the outstanding balance.')
    end

    it 'allows a previous payment to be updated', :vcr do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, total_amount: 5000_00)
      student = FactoryGirl.create(:user_with_verified_bank_account, plan: plan)
      payment = student.payments.create(amount: 5000_00, payment_method: student.bank_accounts.first)
      expect(payment.update(status: "failed")).to be true
    end

    it 'does not include failed payments', :vcr do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, total_amount: 5000_00)
      student = FactoryGirl.create(:user_with_verified_bank_account, plan: plan)
      failed_payment = student.payments.create(amount: 5000_00, payment_method: student.bank_accounts.first)
      failed_payment.update(status: "failed")
      new_payment = student.payments.new(amount: 5000_00, payment_method: student.bank_accounts.first)
      expect(new_payment.valid?).to be true
    end
  end

  describe '#total_amount' do
    it 'returns payment amount plus fees', :vcr do
      student = FactoryGirl.create(:user_with_credit_card)
      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)
      expect(payment.total_amount).to be 618_21
    end
  end

  describe "#send_payment_receipt" do
    it "emails the student a receipt after successful payment", :vcr do
      student = FactoryGirl.create(:user_with_credit_card)

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :subject => "Epicodus tuition payment receipt",
          :text => "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
      )
    end
  end

  describe "failed" do
    it "emails the student a failure notice if payment status is updated to 'failed'", :vcr do
      student = FactoryGirl.create(:user_with_credit_card)

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = student.payments.create(amount: 600_00, payment_method: student.credit_cards.first)
      payment.update(status: 'failed')

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => ENV['FROM_EMAIL_PAYMENT'],
          :to => student.email,
          :subject => "Epicodus payment failure notice",
          :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
      )
    end

    it "switches their recurring active status to false", :vcr do
      student = FactoryGirl.create(:user_with_credit_card)
      student.update(recurring_active: true)
      payment = FactoryGirl.create(:payment, student: student)
      payment.update(status: 'failed')
      expect(student.recurring_active?).to be false
    end
  end
end
