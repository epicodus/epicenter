require 'rails_helper'

describe BankAccount do
  it { should validate_presence_of :account_uri }
  it { should validate_presence_of :user_id }
  it { should belong_to :user }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:bank_account) { FactoryGirl.create :bank_account }

    it "creates a verification before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.verification_uri).to_not be_nil
    end
  end

  describe ".active" do
    it "only includes active bank accounts", :vcr do
      active_bank_account = FactoryGirl.create(:bank_account, active: true)
      inactive_bank_account = FactoryGirl.create(:bank_account, active: false)
      expect(BankAccount.active).to eq [active_bank_account]
    end
  end

  describe ".billable_today", :vcr do
    it "includes bank_accounts that have not been billed in the last month" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.payments.first.update(created_at: 1.month.ago)
      expect(BankAccount.billable_today).to eq [bank_account]
    end

    it "does not include bank_accounts that have been billed in the last month" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.payments.first.update(created_at: 2.weeks.ago)
      expect(BankAccount.billable_today).to eq []
    end

    it "does not include bank_accounts that are inactive" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.update(active: false)
      bank_account.payments.first.update(created_at: 1.month.ago)
      expect(BankAccount.billable_today).to eq []
    end

    it "returns all bank_accounts that are due for payment" do
      bank_account1 = FactoryGirl.create(:verified_bank_account)
      bank_account1.payments.first.update(created_at: 1.month.ago)

      bank_account2 = FactoryGirl.create(:verified_bank_account)
      bank_account2.payments.first.update(created_at: 1.month.ago)

      bank_account3 = FactoryGirl.create(:verified_bank_account)
      bank_account3.payments.first.update(created_at: 2.weeks.ago)

      bank_account4 = FactoryGirl.create(:verified_bank_account, active: false)
      bank_account4.update(active: false)
      bank_account4.payments.first.update(created_at: 1.month.ago)

      expect(BankAccount.billable_today).to eq [bank_account1, bank_account2]
    end

    it "handles months with different amounts of days" do
      include ActiveSupport::Testing::TimeHelpers
      bank_account = FactoryGirl.create(:verified_bank_account)
      travel_to(Date.parse("January 31, 2014")) do
        FactoryGirl.create(:payment, bank_account: bank_account)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(BankAccount.billable_today).to eq [bank_account]
      end
    end
  end

  describe ".billable_in_three_days", :vcr do
    include ActiveSupport::Testing::TimeHelpers
    it 'tells you which accounts are billable in three days' do
      payment = nil
      travel_to(Date.parse("January 5, 2014")) do
        payment = FactoryGirl.create(:payment)
      end
      bank_account = payment.bank_account
      travel_to(Date.parse("February 2, 2014")) do
        expect(BankAccount.billable_in_three_days).to eq [bank_account]
      end
    end

    it 'does not include accounts that are billable in more than three days' do
      payment = nil
      travel_to(Date.parse("January 6, 2014")) do
        payment = FactoryGirl.create(:payment)
      end
      bank_account = payment.bank_account
      travel_to(Date.parse("February 2, 2014")) do
        expect(BankAccount.billable_in_three_days).to eq []
      end
    end

    it 'does not include accounts that are billable in less than three days' do
      payment = nil
      travel_to(Date.parse("January 4, 2014")) do
        payment = FactoryGirl.create(:payment)
      end
      bank_account = payment.bank_account
      travel_to(Date.parse("February 2, 2014")) do
        expect(BankAccount.billable_in_three_days).to eq []
      end
    end
  end

  describe ".bill_bank_accounts", :vcr do
    it "bills all bank_accounts that are due today" do
      bank_account1 = FactoryGirl.create(:verified_bank_account)
      bank_account1.payments.first.update(created_at: 1.month.ago)

      bank_account2 = FactoryGirl.create(:verified_bank_account)
      bank_account2.payments.first.update(created_at: 1.weeks.ago)

      BankAccount.bill_bank_accounts

      expect(bank_account1.payments.length).to eq 2
      expect(bank_account2.payments.length).to eq 1
    end
  end
end
