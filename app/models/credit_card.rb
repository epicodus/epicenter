class CreditCard < PaymentMethod
  before_create :set_verified_true
  after_create :ensure_primary_method_exists


  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

  def starting_status
    "succeeded"
  end

private
  def set_verified_true
    self.verified = true
  end
end
