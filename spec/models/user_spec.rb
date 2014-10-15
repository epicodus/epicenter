require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should validate_presence_of :plan_id }
  it { should validate_presence_of :cohort_id }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should belong_to :plan }
  it { should have_many :attendance_records }
  it { should belong_to :cohort }

  describe ".recurring_active" do
    it "only includes users that are recurring_active", :vcr do
      recurring_active_user = FactoryGirl.create(:user_with_recurring_active)
      non_recurring_active_user  = FactoryGirl.create(:user_with_verified_bank_account)
      expect(User.recurring_active).to eq [recurring_active_user]
    end
  end

  describe ".billable_today", :vcr do
    it "includes users that have not been billed in the last month" do
      user = FactoryGirl.create(:user_with_recurring_due)
      expect(User.billable_today).to eq [user]
    end

    it "does not include users that have been billed in the last month" do
      bank_account = FactoryGirl.create(:user_with_recurring_not_due)
      expect(User.billable_today).to eq []
    end

    it "only includes users that are recurring_active" do
      user = FactoryGirl.create(:user_with_recurring_due)
      user.update(recurring_active: false)
      expect(User.billable_today).to eq []
    end

    it "returns all users that are due for payment" do
      user1 = FactoryGirl.create(:user_with_recurring_due)
      user2 = FactoryGirl.create(:user_with_recurring_due)
      user3 = FactoryGirl.create(:user_with_recurring_not_due)
      user4 = FactoryGirl.create(:user_with_recurring_due)
      user4.update(recurring_active: false)
      expect(User.billable_today).to eq [user1, user2]
    end

    include ActiveSupport::Testing::TimeHelpers
    it "handles months with different amounts of days" do
      user = nil
      travel_to(Date.parse("January 31, 2014")) do
        user = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(User.billable_today).to eq [user]
      end
    end
  end

  describe ".billable_in_three_days", :vcr do
    include ActiveSupport::Testing::TimeHelpers
    it 'tells you which users are billable in three days' do
      user = nil
      travel_to(Date.parse("January 5, 2014")) do
        user = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(User.billable_in_three_days).to eq [user]
      end
    end

    it 'works even if the payment is made at a different time than the method is run' do
      user = nil
      travel_to(Time.new(2014, 1, 5, 12, 0, 0, 0)) do
        user = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Time.new(2014, 2, 2, 15, 0, 0, 0)) do
        expect(User.billable_in_three_days).to eq [user]
      end
    end

    it 'does not include users that are billable in more than three days' do
      user = nil
      travel_to(Date.parse("January 6, 2014")) do
        user = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(User.billable_in_three_days).to eq []
      end
    end

    it 'does not include users that are billable in less than three days' do
      user = nil
      travel_to(Date.parse("January 4, 2014")) do
        user = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(User.billable_in_three_days).to eq []
      end
    end
  end

  describe ".email_upcoming_payees" do
    include ActiveSupport::Testing::TimeHelpers

    it "emails users who are due in 3 days", :vcr do
      user = nil
      travel_to(Date.parse("January 5, 2014")) do
        user = FactoryGirl.create(:user_with_recurring_active)
      end

      expect(RestClient).to receive(:post).with(
        "https://api:#{ENV['MAILGUN_API_KEY']}@api.mailgun.net/v2/epicodus.com/messages",
        :from => "michael@epicodus.com",
        :to => user.email,
        :bcc => "michael@epicodus.com",
        :subject => "Upcoming Epicodus tuition payment",
        :text => "Hi #{user.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!"
      )

      travel_to(Date.parse("February 2, 2014")) do
        User.email_upcoming_payees
      end
    end
  end

  describe ".bill_bank_accounts", :vcr do
    it "bills all bank_accounts that are due today" do
      user = FactoryGirl.create(:user_with_recurring_due)
      expect { User.bill_bank_accounts }.to change { user.payments.count }.by 1
    end

    it "does not bill bank accounts that are not due today" do
      user = FactoryGirl.create(:user_with_recurring_not_due)
      expect { User.bill_bank_accounts }.to change { user.payments.count }.by 0
    end
  end

  describe "#upfront_payment_due?", :vcr do
    let(:user) { FactoryGirl.create :user_with_verified_bank_account }

    it "is true if user has upfront payment and no payments have been made" do
      expect(user.upfront_payment_due?).to be true
    end

    it "is false if user has no upfront payment" do
      user.plan.upfront_amount = 0
      expect(user.upfront_payment_due?).to be false
    end

    it "is false if user has made any payments" do
      user = FactoryGirl.create :user_with_upfront_payment
      expect(user.upfront_payment_due?).to be false
    end
  end

  describe "#make_upfront_payment", :vcr do
    it "makes a payment for the upfront amount of the user's plan" do
      user = FactoryGirl.create(:user_with_verified_bank_account)
      user.make_upfront_payment
      expect(user.payments.first.amount).to eq user.plan.upfront_amount
    end
  end

  describe "#start_recurring_payments", :vcr do
    it "makes a payment for the recurring amount of the users's plan" do
      user = FactoryGirl.create(:user_with_verified_bank_account)
      user.start_recurring_payments
      expect(user.payments.first.amount).to eq user.plan.recurring_amount
    end

    it 'sets the bank account to be recurring_active' do
      user = FactoryGirl.create(:user_with_verified_bank_account)
      user.start_recurring_payments
      expect(user.recurring_active).to eq true
    end
  end

  describe '#signed_in_today?' do
    let(:user) { FactoryGirl.create(:user) }

    it 'is false if the user has not signed in today' do
      expect(user.signed_in_today?).to eq false
    end

    it 'is true if the user has already signed in today' do
      attendance_record = FactoryGirl.create(:attendance_record, user: user)
      expect(user.signed_in_today?).to eq true
    end
  end
end
