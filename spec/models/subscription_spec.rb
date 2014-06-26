require 'rails_helper'

describe Subscription do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }
  it { should have_many :payments }

  describe "verify bank account" do
    before :all do
      @subscription = create_subscription
    end

    it "creates a verification before_create" do
      expect(@subscription.verification_uri).to_not be_nil
    end

    it "does not confirm a verification when incorrect deposits are entered" do
      @subscription.first_deposit = 2
      @subscription.second_deposit = 1
      expect(@subscription.confirm_verification).to be false
    end

    it "confirms a verification when correct deposits are entered" do
      @subscription.first_deposit = 1
      @subscription.second_deposit = 1
      expect(@subscription.confirm_verification).to be true
      expect(@subscription.verified).to be true
    end
  end
end

