class CreditCard < PaymentMethod
  before_create :create_stripe_card
  before_create :set_verified_true
  before_create :get_last_four_string
  after_create :ensure_primary_method_exists


  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

  def starting_status
    "succeeded"
  end

private

  def create_stripe_card
    begin
      card = student.stripe_customer.sources.create(:source => stripe_token)
      self.stripe_id = card.id
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def get_last_four_string
    begin
      customer = student.stripe_customer
      stripe_credit_card = customer.cards.retrieve(stripe_id)
      self.last_four_string = stripe_credit_card.last4
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def set_verified_true
    self.verified = true
  end
end
