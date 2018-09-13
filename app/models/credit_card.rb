class CreditCard < PaymentMethod
  before_create :set_verified_true

  def calculate_fee(amount)
    amount * 3 / 100
  end

  def starting_status
    "succeeded"
  end

private
  def set_verified_true
    self.verified = true
  end
end
