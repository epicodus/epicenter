class BankAccount < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  attr_accessor :first_deposit, :second_deposit
  validates :account_uri, presence: true
  validates :user_id, presence: true

  belongs_to :user
  has_many :payments

  before_create :create_verification

  def self.billable_today
    active.select do |bank_account|
      bank_account.payments.last.created_at < 1.month.ago if !bank_account.payments.empty?
    end
  end

  def self.bill_bank_accounts
    billable_today.each do |bank_account|
      bank_account.payments.create(amount: 625_00)
    end
  end

private

  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end
end
