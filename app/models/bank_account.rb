class BankAccount < ActiveRecord::Base
  scope :active, -> { where(status: 'active') }

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user
  has_many :payments

  before_create :create_verification
  before_create :activate_bank_account

  after_update :create_payment, if: :confirming_account?

  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end

  def self.billable_today
    active.select do |bank_account|
      bank_account.payments.last.created_at < 1.month.ago if !bank_account.payments.empty?
    end
  end

  def self.bill_bank_accounts
    billable_today.each do |bank_account|
      bank_account.send(:create_payment)
    end
  end

private

  def activate_bank_account
    self.status = "active"
  end

  def create_payment
    self.payments.create(amount: 65000)
  end

  def confirming_account?
    first_deposit && second_deposit
  end
end
