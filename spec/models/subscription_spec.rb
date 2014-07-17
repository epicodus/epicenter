require 'rails_helper'

describe Subscription do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:subscription) { FactoryGirl.create :subscription }

    it "sets status to 'active' before_create" do
      subscription = FactoryGirl.create(:subscription)
      expect(subscription.status).to eq "active"
    end

    it "creates a verification before_create" do
      subscription = FactoryGirl.create(:subscription)
      expect(subscription.verification_uri).to_not be_nil
    end
  end

  describe "#create_payment", :vcr do
    it 'is called when the model is updated with first and second deposits' do
      subscription = FactoryGirl.create(:subscription)
      subscription.update(first_deposit: 1, second_deposit: 1)
      expect(subscription.payments.length).to eq 1
      expect(subscription.payments.first.amount).to eq 65000
    end
  end

  describe ".billable_today", :vcr do
    it "includes subscriptions that have not been billed in the last month" do
      subscription = FactoryGirl.create(:subscription)
      subscription.update(first_deposit: 1, second_deposit: 1)
      subscription.payments.first.update(created_at: 1.month.ago)
      expect(Subscription.billable_today).to eq [subscription]
    end

    it "does not include subscriptions that have been billed in the last month" do
      subscription = FactoryGirl.create(:subscription)
      subscription.update(first_deposit: 1, second_deposit: 1)
      subscription.payments.first.update(created_at: 2.weeks.ago)
      expect(Subscription.billable_today).to eq []
    end

    it "does not include subscriptions that are inactive" do
      subscription = FactoryGirl.create(:subscription)
      subscription.update(first_deposit: 1, second_deposit: 1, status: 'inactive')
      subscription.payments.first.update(created_at: 1.month.ago)
      expect(Subscription.billable_today).to eq []
    end

    it "returns all subscriptions that are due for payment" do
      subscription1 = FactoryGirl.create(:subscription)
      subscription1.update(first_deposit: 1, second_deposit: 1)
      subscription1.payments.first.update(created_at: 1.month.ago)

      subscription2 = FactoryGirl.create(:subscription)
      subscription2.update(first_deposit: 1, second_deposit: 1)
      subscription2.payments.first.update(created_at: 1.month.ago)

      subscription3 = FactoryGirl.create(:subscription)
      subscription3.update(first_deposit: 1, second_deposit: 1)
      subscription3.payments.first.update(created_at: 2.weeks.ago)

      subscription4 = FactoryGirl.create(:subscription)
      subscription4.update(first_deposit: 1, second_deposit: 1, status: 'inactive')
      subscription4.payments.first.update(created_at: 1.month.ago)

      expect(Subscription.billable_today).to eq [subscription1, subscription2]
    end

    include ActiveSupport::Testing::TimeHelpers

    it "handles months with different amounts of days" do
      subscription = FactoryGirl.create(:subscription)
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
      subscription1 = FactoryGirl.create(:subscription)
      subscription1.update(first_deposit: 1, second_deposit: 1)
      subscription1.payments.first.update(created_at: 1.month.ago)

      subscription2 = FactoryGirl.create(:subscription)
      subscription2.update(first_deposit: 1, second_deposit: 1)
      subscription2.payments.first.update(created_at: 1.weeks.ago)

      Subscription.bill_subscriptions

      expect(subscription1.payments.length).to eq 2
      expect(subscription2.payments.length).to eq 1
    end
  end
end
