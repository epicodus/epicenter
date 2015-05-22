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
      student.stripe_customer.sources.create(:source => stripe_token)
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def get_last_four_string
    begin
      customer = student.stripe_customer
      customer.sources.data.each do |data|
        if data.object == "card"
          self.last_four_string = data.last4
        end
      end
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def set_verified_true
    self.verified = true
  end
end
