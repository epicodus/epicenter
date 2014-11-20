class BankAccount < PaymentMethod
  before_create :create_verification
  before_create :get_last_four_string

  def fetch_balanced_account
    Balanced::BankAccount.fetch(account_uri)
  end

  def calculate_fee(amount)
    0
  end

  def starting_status
    "pending"
  end


private
  def create_verification
    verification = Verification.new(bank_account: self)
    verification.create_test_deposits
  end

  def get_last_four_string
    self.last_four_string = fetch_balanced_account.account_number
  end
end
