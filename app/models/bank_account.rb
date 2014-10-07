class BankAccount < ActiveRecord::Base
  scope :recurring_active, -> { where(recurring_active: true) }

  validates :account_uri, presence: true
  validates :user_id, presence: true

  belongs_to :user
  has_one :plan, through: :user
  has_many :payments

  before_create :create_verification

  def self.billable_today
    recurring_active.select do |bank_account|
      bank_account.payments.last.created_at < 1.month.ago
    end
  end

  def self.billable_in_three_days
    recurring_active.select do |bank_account|
      (bank_account.payments.last.created_at - 3.days) == 1.month.ago
    end
  end

  def self.email_upcoming_payees
    billable_in_three_days.each do |bank_account|
      RestClient.post(
        "https://api:#{ENV['MAILGUN_API_KEY']}@api.mailgun.net/v2/epicodus.com/messages",
        :from => "michael@epicodus.com",
        :to => bank_account.user.email,
        :bcc => "michael@epicodus.com",
        :subject => "Upcoming Epicodus tuition payment",
        :text => "Hi #{bank_account.user.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!"
      )
    end
  end

  def self.bill_bank_accounts
    billable_today.each do |bank_account|
      bank_account.payments.create(amount: 625_00)
    end
  end

  def make_upfront_payment
    payments.create!(amount: plan.upfront_amount)
  end

  def start_recurring_payments
    update!(recurring_active: true)
    payments.create!(amount: plan.recurring_amount)
  end

private

  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end
end
