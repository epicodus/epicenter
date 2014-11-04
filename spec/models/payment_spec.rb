require 'rails_helper'

describe Payment do

  it { should belong_to :student }
  it { should belong_to :payment_method }
  it { should validate_presence_of :student_id }
  it { should validate_presence_of :payment_method }
  it { should validate_presence_of :amount }

  describe '.order_by_latest scope' do
    let!(:payment_one) { FactoryGirl.create(:payment) }
    let!(:payment_two) { FactoryGirl.create(:payment) }

    it 'orders by created_at, descending', :vcr do
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
    end
  end

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      student = FactoryGirl.create :user_with_verified_bank_account
      student.payments.create(amount: 100, payment_method: student.bank_accounts.first)
      expect(student.payments.first.payment_uri).to_not be_nil
    end

    it "doesn't make a payment with a bad card", :vcr do
      student = FactoryGirl.create :user_with_invalid_credit_card
      student.payments.create(amount: 100, payment_method: student.credit_cards.first)
      expect(student.payments.first.payment_uri).to be_nil
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
        { :from => "michael@epicodus.com",
          :to => student.email,
          :bcc => "michael@epicodus.com",
          :subject => "Epicodus tuition payment receipt",
          :text => "Hi #{student.name}. This is to confirm your payment of $618.21 for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
      )
    end
  end
end
