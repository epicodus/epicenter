class BankAccount < PaymentMethod
  before_create :get_last_four_string
  before_create :create_verification

  def fetch_balanced_account
    begin
      Balanced::BankAccount.fetch(account_uri)
    rescue Balanced::Error => exception
      errors.add(:base, exception.description)
      false
    end
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
    if balanced_account = fetch_balanced_account
      self.last_four_string = balanced_account.account_number
    else
      false
    end
  end
end
