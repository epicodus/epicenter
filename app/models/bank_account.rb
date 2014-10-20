class BankAccount < ActiveRecord::Base
  validates :account_uri, presence: true
  validates :user_id, presence: true

  belongs_to :user
  has_many :payments, :as => :payment_method

  before_create :create_verification

  def fetch_balanced_account
    Balanced::BankAccount.fetch(account_uri)
  end

  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end
end
