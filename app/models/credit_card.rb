class CreditCard < PaymentMethod
  # before_create :get_last_four_string
  before_create :set_verified_true

  after_create :ensure_primary_method_exists

  # def fetch_balanced_account
  #   begin
  #     Balanced::Card.fetch(account_uri)
  #   rescue Balanced::PaymentRequired => exception
  #     errors.add(:base, exception.description)
  #     false
  #   end
  # end

  # def create_stripe_customer
  #   token = params[:stripe_token]
  #   customer = Stripe::Customer.create(source: token, description: student.email)
  #   save_stripe_customer_id(customer.id)
  # end

  # def save_stripe_customer_id(customer_id)
  #   student.update_attributes(stripe_customer_id: customer_id)
  #   student.save
  # end

  # def get_stripe_customer_id(user)
  #   student.stripe_customer_id
  # end

  # def fetch_stripe_account
  #   customer_id = get_stripe_customer_id(student)
  #   begin
  #     customer = Stripe::Customer.retreive(customer_id)
  #     customer.sources.retreive(source)
  #   rescue Stripe::CardError => exception
  #     errors.add(:base, exception.message)
  #     false
  #   end
  # end

  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

  def starting_status
    "succeeded"
  end

private
#   def get_last_four_string
#     if balanced_account = fetch_balanced_account
#       self.last_four_string = balanced_account.number
#     else
#       false
#     end
#   end

  # def get_last_four_string
  #   if stripe_account = fetch_stripe_account
  #     self.last_four_string = stripe_account.last4
  #   else
  #     false
  #   end
  # end

  def set_verified_true
    self.verified = true
  end
end
