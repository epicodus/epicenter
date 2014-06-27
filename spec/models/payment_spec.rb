require 'rails_helper'

describe Payment do

  it { should belong_to :subscription }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :subscription_id }

  describe "make a payment" do
    it "makes a successful payment" do
      subscription = create_subscription
      subscription.first_deposit = 1
      subscription.second_deposit = 1
      subscription.confirm_verification
      subscription.payments.create(amount: 100)
      expect(subscription.payments.first.payment_uri).to_not be_nil
    end
  end
end
