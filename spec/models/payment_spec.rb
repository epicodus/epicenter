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
end

