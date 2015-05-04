class CreditCard < PaymentMethod
  before_create :get_last_four_string
  before_create :set_verified_true
  after_create :ensure_primary_method_exists

  def create_stripe_customer
    token = params[:stripe_token]
    customer = Stripe::Customer.create(source: token, description: student.email)
    save_stripe_customer_id(customer.id)
  end

  def save_stripe_customer_id(customer_id)
    student.update_attributes(stripe_customer_id: customer_id)
    student.save
  end

  def get_stripe_customer_id(user)
    student.stripe_customer_id
  end

  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

  def starting_status
    "succeeded"
  end

private
  def get_last_four_string
    customer_id = get_stripe_customer_id(student)
    begin
      customer = Stripe::Customer.retreive(customer_id)
      customer.sources.data.retreive(last4)
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def set_verified_true
    self.verified = true
  end
end
