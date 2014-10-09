class BankAccount < ActiveRecord::Base
  validates :account_uri, presence: true
  validates :user_id, presence: true

  belongs_to :user
  has_one :plan, through: :user
  has_many :payments

  before_create :create_verification

private

  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end
end
