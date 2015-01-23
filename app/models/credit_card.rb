class CreditCard < PaymentMethod
  before_create :get_last_four_string
  before_create :set_verified_true

  after_create :ensure_primary_method_exists

  def fetch_balanced_account
    begin
      Balanced::Card.fetch(account_uri)
    rescue Balanced::PaymentRequired => exception
      errors.add(:base, exception.description)
      false
    end
  end

  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

  def starting_status
    "succeeded"
  end

private
  def get_last_four_string
    if balanced_account = fetch_balanced_account
      self.last_four_string = balanced_account.number
    else
      false
    end
  end

  def set_verified_true
    self.verified = true
  end
end
