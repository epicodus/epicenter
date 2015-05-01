class BankAccount < PaymentMethod
  # before_create :get_last_four_string
  before_create :create_verification

  # def fetch_balanced_account
  #   begin
  #     Balanced::BankAccount.fetch(account_uri)
  #   rescue Balanced::Error => exception
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

  # def get_last_four_string
  #   if balanced_account = fetch_balanced_account
  #     self.last_four_string = balanced_account.account_number
  #   else
  #     false
  #   end
  # end

  # def get_last_four_string
  #   if stripe_account = fetch_stripe_account
  #     self.last_four_string = stripe_account.last4
  #   else
  #     false
  #   end
  # end
end
