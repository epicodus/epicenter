require 'rails_helper'

describe Payment do

  it { should belong_to :user }
  it { should belong_to :payment_method }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :payment_method }

  describe '.order_by_latest scope' do
    let!(:payment_one) { FactoryGirl.create(:payment) }
    let!(:payment_two) { FactoryGirl.create(:payment) }

    it 'orders by created_at, descending', :vcr do
      expect(Payment.order_by_latest).to eq [payment_two, payment_one]
    end
  end

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      user = FactoryGirl.create :user_with_verified_bank_account
      user.payments.create(amount: 100, payment_method: user.bank_account)
      expect(user.payments.first.payment_uri).to_not be_nil
    end

    it "doesn't make a payment with a bad card", :vcr do
      user = FactoryGirl.create :user_with_invalid_credit_card
      user.payments.create(amount: 100, payment_method: user.credit_card)
      expect(user.payments.first.payment_uri).to be_nil
    end
  end

  describe '#check_if_paid_up' do
    it 'does nothing if user is not paid up', :vcr do
      user = FactoryGirl.create(:user_with_recurring_active)
      payment = user.payments.create(amount: 600_00, payment_method: user.credit_card)
      expect(user.recurring_active).to be true
    end

    let(:plan) { FactoryGirl.create(:recurring_plan_with_upfront_payment, total_amount: 5000_00) }
    let(:user) { FactoryGirl.create(:user_with_credit_card, plan: plan) }

    it 'sets recurring_active to false if user is paid up', :vcr do
      payment = user.payments.create(amount: 5000_00, payment_method: user.credit_card)
      expect(user.recurring_active).to be false
    end

    it 'sets recurring_active to false if user has paid more than the total_amount', :vcr do
      payment = user.payments.create(amount: 5100_00, payment_method: user.credit_card)
      expect(user.recurring_active).to be false
    end
  end

  describe "#send_payment_receipt" do
    it "emails the user a receipt after successful payment", :vcr do
      user = FactoryGirl.create(:user_with_credit_card)

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      payment = user.payments.create(amount: 600_00, payment_method: user.credit_card)

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => "michael@epicodus.com",
          :to => user.email,
          :bcc => "michael@epicodus.com",
          :subject => "Epicodus tuition payment receipt",
          :text => "Hi #{user.name}. This is to confirm your payment of $618.21 for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
      )
    end
  end
end

