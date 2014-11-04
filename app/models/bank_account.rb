class BankAccount < ActiveRecord::Base
  validates :account_uri, presence: true
  validates :student_id, presence: true

  belongs_to :student
  has_many :payments, :as => :payment_method

  before_create :create_verification
  before_create :get_last_four_string

  def fetch_balanced_account
    Balanced::BankAccount.fetch(account_uri)
  end

  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end

  def calculate_fee(amount)
    0
  end

private
  def get_last_four_string
    self.last_four_string = fetch_balanced_account.account_number
  end
end
