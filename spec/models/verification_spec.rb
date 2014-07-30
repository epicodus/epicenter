require 'rails_helper'

describe Verification, :vcr do
  describe "#create_test_deposits" do
    it "creates a verification for the balanced account of the given bank_account" do
      bank_account = FactoryGirl.build(:bank_account)
      verification = Verification.new(bank_account: bank_account)
      verification.create_test_deposits
      verification_id = Balanced::BankAccount.fetch(bank_account.account_uri).links["bank_account_verification"]
      expect(verification_id).not_to be_nil
    end

    it "sets the verification uri to the given bank_account" do
      bank_account = FactoryGirl.build(:bank_account)
      verification = Verification.new(bank_account: bank_account)
      verification.create_test_deposits
      expect(bank_account.verification_uri).not_to be_nil
    end
  end

  describe "#confirm" do
    context "with correct amounts" do
      it "sets the user's bank_account verified status to true" do
        user = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: user.bank_account, first_deposit: 1, second_deposit: 1)
        verification.confirm
        expect(user.bank_account.verified).to be true
      end

      it "returns true" do
        user = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: user.bank_account, first_deposit: 1, second_deposit: 1)
        expect(verification.confirm).to be true
      end

      it "cleans the input" do
        user = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: user.bank_account, first_deposit: "$0.01", second_deposit: 1)
        expect(verification.confirm).to be true
      end

      it "sets the user's bank account active status to true" do
        bank_account = FactoryGirl.create(:bank_account)
        verification = Verification.new(bank_account: bank_account, first_deposit: 1, second_deposit: 1)
        verification.confirm
        expect(bank_account.active).to be true
      end

      it "create the first payment for the user" do
        bank_account = FactoryGirl.create(:bank_account)
        verification = Verification.new(bank_account: bank_account, first_deposit: 1, second_deposit: 1)
        verification.confirm
        expect(Payment.count).to equal 1
      end
    end

    context "with incorrect amounts" do
      it "returns false" do
        user = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: user.bank_account, first_deposit: 1, second_deposit: 2)
        expect(verification.confirm).to be false
      end

      it "adds errors to the object" do
        user = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: user.bank_account, first_deposit: 1, second_deposit: 2)
        verification.confirm
        expect(verification.errors.full_messages).to eq ["Authentication amounts do not match. Your request id is OHMa59ded900eea11e4a4e806429171ffad."]
      end
    end
  end
end
