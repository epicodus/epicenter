class BankAccount < PaymentMethod
  before_update :verify_account, unless: ->(bank_account) { bank_account.verified? }

  attr_accessor :first_deposit, :second_deposit, :plaid_public_token, :plaid_account_id

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
      true
    rescue Stripe::CardError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end

  def exchange_plaid_token
    environment = Rails.env.production? ? :production : :sandbox
    client = Plaid::Client.new(env: environment, client_id: ENV['PLAID_CLIENT_ID'], secret: ENV['PLAID_SECRET_KEY'])
    exchange_token_response = client.item.public_token.exchange(plaid_public_token)
    access_token = exchange_token_response['access_token']
    stripe_response = client.processor.stripe.bank_account_token.create(access_token, plaid_account_id)
    self.stripe_token = stripe_response['stripe_bank_account_token']
    self.verified = true
  end
end
