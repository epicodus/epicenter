require 'rails_helper'

describe Subscription do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }

  it "creates a verification after creation" do
    Balanced.configure('ak-test-2q80HU8DISm2atgm0iRKRVIePzDb34qYp')
    bank_account = Balanced::BankAccount.new(
      :account_number => '9900000002',
      :account_type => 'checking',
      :name => 'Johann Bernoulli',
      :routing_number => '021000021'
    ).save
    subscription = Subscription.create(account_uri: bank_account.href)
    expect(subscription.verification_uri).to_not be_nil
  end
end

