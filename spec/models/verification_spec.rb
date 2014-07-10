require 'rails_helper'

describe Verification do
  describe "#initialize", :vcr do
    it "creates a verification for the balanced account of the given subscription" do
      bank_account = create_bank_account
      subscription = Subscription.new(account_uri: bank_account.href)
      new_verification = Verification.new(subscription)
      verification_id = Balanced::BankAccount.fetch(bank_account.href).links["bank_account_verification"]
      expect(verification_id).not_to be_nil
    end
    it "saves the verification uri to the given subscription" do
      bank_account = create_bank_account
      subscription = Subscription.new(account_uri: bank_account.href)
      new_verification = Verification.new(subscription)
      expect(subscription.verification_uri).not_to be_nil
    end
  end
end
