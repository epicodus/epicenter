require 'rails_helper'

describe Subscription do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }

  it "creates a verification after creation" do
    subscription = Subscription.create(account_uri: "/bank_accounts/BA1W9SQLf5YRaGbUGiNIO2fb")
    expect(subscription.verification_uri).to_not be_nil
  end
end
