require 'rails_helper'

describe BankAccount do
  it { should validate_presence_of :account_uri }
  it { should belong_to :user }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:bank_account) { FactoryGirl.create :bank_account }

    it "sets status to 'active' before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.status).to eq "active"
    end

    it "creates a verification before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.verification_uri).to_not be_nil
    end
  end

  describe "#create_payment", :vcr do
    it 'is called when the model is updated with first and second deposits' do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.update(first_deposit: 1, second_deposit: 1)
      expect(bank_account.payments.length).to eq 1
      expect(bank_account.payments.first.amount).to eq 65000
    end
  end

  describe ".billable_today", :vcr do
    it "includes bank_accounts that have not been billed in the last month" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.update(first_deposit: 1, second_deposit: 1)
      bank_account.payments.first.update(created_at: 1.month.ago)
      expect(BankAccount.billable_today).to eq [bank_account]
    end

    it "does not include bank_accounts that have been billed in the last month" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.update(first_deposit: 1, second_deposit: 1)
      bank_account.payments.first.update(created_at: 2.weeks.ago)
      expect(BankAccount.billable_today).to eq []
    end

    it "does not include bank_accounts that are inactive" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.update(first_deposit: 1, second_deposit: 1, status: 'inactive')
      bank_account.payments.first.update(created_at: 1.month.ago)
      expect(BankAccount.billable_today).to eq []
    end

    it "returns all bank_accounts that are due for payment" do
      bank_account1 = FactoryGirl.create(:verified_bank_account)
      bank_account1.update(first_deposit: 1, second_deposit: 1)
      bank_account1.payments.first.update(created_at: 1.month.ago)

      bank_account2 = FactoryGirl.create(:verified_bank_account)
      bank_account2.update(first_deposit: 1, second_deposit: 1)
      bank_account2.payments.first.update(created_at: 1.month.ago)

      bank_account3 = FactoryGirl.create(:verified_bank_account)
      bank_account3.update(first_deposit: 1, second_deposit: 1)
      bank_account3.payments.first.update(created_at: 2.weeks.ago)

      bank_account4 = FactoryGirl.create(:verified_bank_account)
      bank_account4.update(first_deposit: 1, second_deposit: 1, status: 'inactive')
      bank_account4.payments.first.update(created_at: 1.month.ago)

      expect(BankAccount.billable_today).to eq [bank_account1, bank_account2]
    end

    include ActiveSupport::Testing::TimeHelpers

    it "handles months with different amounts of days" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      travel_to(Date.parse("January 31, 2014")) do
        bank_account.update(first_deposit: 1, second_deposit: 1)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(BankAccount.billable_today).to eq [bank_account]
      end
    end
  end

  describe ".bill_bank_accounts", :vcr do
    it "bills all bank_accounts that are due today" do
      bank_account1 = FactoryGirl.create(:verified_bank_account)
      bank_account1.update(first_deposit: 1, second_deposit: 1)
      bank_account1.payments.first.update(created_at: 1.month.ago)

      bank_account2 = FactoryGirl.create(:verified_bank_account)
      bank_account2.update(first_deposit: 1, second_deposit: 1)
      bank_account2.payments.first.update(created_at: 1.weeks.ago)

      BankAccount.bill_bank_accounts

      expect(bank_account1.payments.length).to eq 2
      expect(bank_account2.payments.length).to eq 1
    end
  end
end
