require 'rails_helper'

describe Subscription do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:subscription) { create_subscription }
    
    it "sets status to 'active' before_create" do
      expect(subscription.status).to eq "active"
    end

    it "creates a verification before_create" do
      expect(subscription.verification_uri).to_not be_nil
    end

    it "does not confirm a verification when incorrect deposits are entered" do
      subscription.first_deposit = 2
      subscription.second_deposit = 1
      expect(subscription.confirm_verification).to be false
    end

    it "confirms a verification when correct deposits are entered" do
      subscription.first_deposit = 1
      subscription.second_deposit = 1
      expect(subscription.confirm_verification).to be true
      expect(subscription.verified).to be true
    end
  end

  describe "#create_payment", :vcr do
    it 'is called when the model is updated with first and second deposits' do
      subscription = create_subscription
      subscription.update(first_deposit: 1, second_deposit: 1)
      expect(subscription.payments.length).to eq 1
      expect(subscription.payments.first.amount).to eq 65000
    end
  end

  describe ".billable_today", :vcr do
    it "returns all subscriptions that are due for payment" do
      subscription1 = create_subscription
      subscription1.update(first_deposit: 1, second_deposit: 1)
      subscription1.payments.first.update(created_at: 1.month.ago)

      subscription2 = create_subscription
      subscription2.update(first_deposit: 1, second_deposit: 1)
      subscription2.payments.first.update(created_at: 1.month.ago)

      subscription3 = create_subscription
      subscription3.update(first_deposit: 1, second_deposit: 1)
      subscription3.payments.first.update(created_at: 2.weeks.ago)

      subscription4 = create_subscription
      subscription4.update(first_deposit: 1, second_deposit: 1, status: 'inactive')
      subscription4.payments.first.update(created_at: 1.month.ago)

      expect(Subscription.billable_today).to eq [subscription1, subscription2]
    end

    include ActiveSupport::Testing::TimeHelpers

    it "handles months with different amounts of days" do
      subscription = create_subscription
      travel_to(Date.parse("January 31, 2014")) do
        subscription.update(first_deposit: 1, second_deposit: 1)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(Subscription.billable_today).to eq [subscription]
      end
    end
  end

  describe ".bill_subscriptions", :vcr do
    it "bills all subscriptions that are due today" do
      subscription1 = create_subscription
      subscription1.update(first_deposit: 1, second_deposit: 1)
      subscription1.payments.first.update(created_at: 1.month.ago)

      subscription2 = create_subscription
      subscription2.update(first_deposit: 1, second_deposit: 1)
      subscription2.payments.first.update(created_at: 1.weeks.ago)

      Subscription.bill_subscriptions

      expect(subscription1.payments.length).to eq 2
      expect(subscription2.payments.length).to eq 1
    end
  end
end
