class BankAccount < PaymentMethod
  before_create :create_stripe_bank_account
  before_create :get_last_four_string
  before_update :verify_account, unless: 'verified'

  attr_accessor :first_deposit, :second_deposit

  def calculate_fee(amount)
    0
  end

  def starting_status
    "pending"
  end

private

  def verify_account
    customer = student.stripe_customer
    account = customer.bank_accounts.retrieve(stripe_id)
    begin
      account.verify(:amounts => [first_deposit.to_i, second_deposit.to_i])
      update!(verified: true)
      ensure_primary_method_exists
      true
    rescue Stripe::InvalidRequestError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def create_stripe_bank_account
    begin
      account = student.stripe_customer.sources.create(:source => stripe_token)
      self.stripe_id = account.id
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def get_last_four_string
    begin
      customer = student.stripe_customer
      stripe_bank_account = customer.bank_accounts.retrieve(stripe_id)
      self.last_four_string = stripe_bank_account.last4
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end
end
