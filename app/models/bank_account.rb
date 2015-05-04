class BankAccount < PaymentMethod
  before_create :get_last_four_string
  before_create :create_verification

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
    customer_id = get_stripe_customer_id(student)
    begin
      customer = Stripe::Customer.retreive(customer_id)
      customer.sources.data.retreive(last4)
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end
end
