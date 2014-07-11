require 'rails_helper'

describe Payment do

  it { should belong_to :subscription }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :subscription_id }

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      subscription = create_subscription
      Verification.fetch(subscription.verification_uri).confirm(1, 1)
      subscription.payments.create(amount: 100)
      expect(subscription.payments.first.payment_uri).to_not be_nil
    end
  end
end
