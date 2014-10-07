require 'rails_helper'

describe BankAccount do
  it { should validate_presence_of :account_uri }
  it { should validate_presence_of :user_id }
  it { should belong_to :user }
  it { should have_one :plan }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:bank_account) { FactoryGirl.create :bank_account }

    it "creates a verification before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.verification_uri).to_not be_nil
    end
  end

  describe ".recurring_active" do
    it "only includes bank accounts that are recurring_active", :vcr do
      recurring_active_bank_account = FactoryGirl.create(:bank_account, recurring_active: true)
      non_recurring_active_bank_account = FactoryGirl.create(:bank_account, recurring_active: false)
      expect(BankAccount.recurring_active).to eq [recurring_active_bank_account]
    end
  end

  describe ".billable_today", :vcr do
    it "includes bank_accounts that have not been billed in the last month" do
      bank_account = FactoryGirl.create(:recurring_bank_account_due)
      expect(BankAccount.billable_today).to eq [bank_account]
    end

    it "does not include bank_accounts that have been billed in the last month" do
      bank_account = FactoryGirl.create(:recurring_bank_account_not_due)
      expect(BankAccount.billable_today).to eq []
    end

    it "only includes bank accounts that are recurring_active" do
      bank_account = FactoryGirl.create(:recurring_bank_account_due)
      bank_account.update(recurring_active: false)
      expect(BankAccount.billable_today).to eq []
    end

    it "returns all bank_accounts that are due for payment" do
      bank_account1 = FactoryGirl.create(:recurring_bank_account_due)
      bank_account2 = FactoryGirl.create(:recurring_bank_account_due)
      bank_account3 = FactoryGirl.create(:recurring_bank_account_not_due)
      bank_account4 = FactoryGirl.create(:recurring_bank_account_due)
      bank_account4.update(recurring_active: false)
      expect(BankAccount.billable_today).to eq [bank_account1, bank_account2]
    end

    include ActiveSupport::Testing::TimeHelpers
    it "handles months with different amounts of days" do
      bank_account = nil
      travel_to(Date.parse("January 31, 2014")) do
        bank_account = FactoryGirl.create(:new_recurring_bank_account)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(BankAccount.billable_today).to eq [bank_account]
      end
    end
  end

  describe ".billable_in_three_days", :vcr do
    include ActiveSupport::Testing::TimeHelpers
    it 'tells you which accounts are billable in three days' do
      bank_account = nil
      travel_to(Date.parse("January 5, 2014")) do
        bank_account = FactoryGirl.create(:new_recurring_bank_account)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(BankAccount.billable_in_three_days).to eq [bank_account]
      end
    end

    it 'does not include accounts that are billable in more than three days' do
      bank_account = nil
      travel_to(Date.parse("January 6, 2014")) do
        bank_account = FactoryGirl.create(:new_recurring_bank_account)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(BankAccount.billable_in_three_days).to eq []
      end
    end

    it 'does not include accounts that are billable in less than three days' do
      bank_account = nil
      travel_to(Date.parse("January 4, 2014")) do
        bank_account = FactoryGirl.create(:new_recurring_bank_account)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(BankAccount.billable_in_three_days).to eq []
      end
    end
  end

  describe ".email_upcoming_payees" do
    include ActiveSupport::Testing::TimeHelpers

    it "emails users who are due in 3 days", :vcr do
      bank_account = nil
      travel_to(Date.parse("January 5, 2014")) do
        bank_account = FactoryGirl.create(:new_recurring_bank_account)
      end

      expect(RestClient).to receive(:post).with(
        "https://api:#{ENV['MAILGUN_API_KEY']}@api.mailgun.net/v2/epicodus.com/messages",
        :from => "michael@epicodus.com",
        :to => bank_account.user.email,
        :bcc => "michael@epicodus.com",
        :subject => "Upcoming Epicodus tuition payment",
        :text => "Hi #{bank_account.user.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!"
      )

      travel_to(Date.parse("February 2, 2014")) do
        BankAccount.email_upcoming_payees
      end
    end
  end

  describe ".bill_bank_accounts", :vcr do
    it "bills all bank_accounts that are due today" do
      bank_account = FactoryGirl.create(:recurring_bank_account_due)
      expect { BankAccount.bill_bank_accounts }.to change { bank_account.payments.count }.by 1
    end

    it "does not bill bank accounts that are not due today" do
      bank_account = FactoryGirl.create(:recurring_bank_account_not_due)
      expect { BankAccount.bill_bank_accounts }.to change { bank_account.payments.count }.by 0
    end
  end

  describe "#make_upfront_payment", :vcr do
    it "makes a payment for the upfront amount of the bank account's plan" do
      bank_account = FactoryGirl.create(:verified_bank_account)
      bank_account.make_upfront_payment
      expect(bank_account.payments.first.amount).to eq bank_account.plan.upfront_amount
    end
  end

  describe "#start_recurring_payments", :vcr do
    it "makes a payment for the recurring amount of the bank account's plan" do
      bank_account = FactoryGirl.create(:new_recurring_bank_account)
      expect(bank_account.payments.first.amount).to eq bank_account.plan.recurring_amount
    end

    it 'sets the bank account to be recurring_active' do
      bank_account = FactoryGirl.create(:new_recurring_bank_account)
      expect(bank_account.recurring_active).to eq true
    end
  end
end
