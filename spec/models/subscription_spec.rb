require 'rails_helper'

describe Subscription do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }


  describe "verify bank account" do
    before :all do
      Balanced.configure('ak-test-2q80HU8DISm2atgm0iRKRVIePzDb34qYp')
      bank_account = Balanced::BankAccount.new(
        :account_number => '9900000002',
        :account_type => 'checking',
        :name => 'Johann Bernoulli',
        :routing_number => '021000021'
      ).save
      @subscription = Subscription.create(account_uri: bank_account.href)
    end

    it "creates a verification" do
      @subscription.create_verification
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
    end
  end
end

