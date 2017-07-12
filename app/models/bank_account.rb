class BankAccount < PaymentMethod
  before_update :verify_account, unless: 'verified'

  attr_accessor :first_deposit, :second_deposit

  def calculate_fee(_)
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
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end
end
