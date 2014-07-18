require 'rails_helper'

describe Verification do
  describe "#create_test_deposits", :vcr do
    it "creates a verification for the balanced account of the given subscription" do
      subscription = FactoryGirl.build(:subscription)
      verification = Verification.new(subscription: subscription)
      verification.create_test_deposits
      verification_id = Balanced::BankAccount.fetch(subscription.account_uri).links["bank_account_verification"]
      expect(verification_id).not_to be_nil
    end

    it "sets the verification uri to the given subscription" do
      subscription = FactoryGirl.build(:subscription)
      verification = Verification.new(subscription: subscription)
      verification.create_test_deposits
      expect(subscription.verification_uri).not_to be_nil
    end
  end

  describe "#confirm" do
    context "with correct amounts" do
      it "sets the user's subscription verified status to true" do
        user = FactoryGirl.create(:user_with_unverified_subscription)
        verification = Verification.new(user: user, first_deposit: 1, second_deposit: 1)
        verification.confirm
        expect(user.subscription.verified).to be true
      end

      it "returns true" do
        user = FactoryGirl.create(:user_with_unverified_subscription)
        verification = Verification.new(user: user, first_deposit: 1, second_deposit: 1)
        expect(verification.confirm).to be true
      end
    end

    context "with incorrect amounts" do
      it "returns false" do
        user = FactoryGirl.create(:user_with_unverified_subscription)
        verification = Verification.new(user: user, first_deposit: 1, second_deposit: 2)
        expect(verification.confirm).to be false
      end

      it "adds errors to the object" do
        user = FactoryGirl.create(:user_with_unverified_subscription)
        verification = Verification.new(user: user, first_deposit: 1, second_deposit: 2)
        verification.confirm
        expect(verification.errors.full_messages).to eq ["Authentication amounts do not match."]
      end
    end
  end
end
