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
      it "sets the student's bank_account verified status to true" do
        student = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: student.bank_accounts.first, first_deposit: 1, second_deposit: 1)
        verification.confirm
        expect(student.bank_accounts.first.verified).to be true
      end

      it "returns true" do
        student = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: student.bank_accounts.first, first_deposit: 1, second_deposit: 1)
        expect(verification.confirm).to be true
      end

      it "sets the confirmed bank account as the primary payment method if student does not have one" do
        bank_account = FactoryGirl.create(:verified_bank_account)
        expect(bank_account.student.primary_payment_method).to eq bank_account
      end

      it "cleans the input" do
        student = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: student.bank_accounts.first, first_deposit: "$0.01", second_deposit: 1)
        expect(verification.confirm).to be true
      end
    end

    context "with incorrect amounts" do
      it "returns false" do
        student = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: student.bank_accounts.first, first_deposit: 1, second_deposit: 2)
        expect(verification.confirm).to be false
      end

      it "adds errors to the object" do
        student = FactoryGirl.create(:user_with_unverified_bank_account)
        verification = Verification.new(bank_account: student.bank_accounts.first, first_deposit: 1, second_deposit: 2)
        verification.confirm
        expect(verification.errors.full_messages).to eq ["Authentication amounts do not match. Your request id is OHM457f68b4644c11e4bc0006429171ffad."]
      end
    end
  end
end
