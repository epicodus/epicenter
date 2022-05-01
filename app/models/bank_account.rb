class BankAccount < PaymentMethod
  before_update :verify_account, unless: ->(bank_account) { bank_account.verified? }

  attr_accessor :first_deposit, :second_deposit, :plaid_public_token, :plaid_account_id

  def calculate_fee(_)
    0
  end

  def starting_status
    "pending"
  end

  def create_plaid_link_token
    link_token_create_request = Plaid::LinkTokenCreateRequest.new({
      :user => { :client_user_id => student.id.to_s },
      :client_name => 'Epicodus',
      :products => ['auth'],
      :country_codes => ['US'],
      :language => 'en'
    })
    link_token_response = plaid_client.link_token_create(link_token_create_request)
    link_token_response.link_token # Pass result to client-side to initialize Link and retrieve public_token
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
    request = Plaid::ItemPublicTokenExchangeRequest.new({ public_token: plaid_public_token })
    response = plaid_client.item_public_token_exchange(request)
    access_token = response.access_token
    processor_token_create_request = Plaid::ProcessorStripeBankAccountTokenCreateRequest.new
    processor_token_create_request.access_token = access_token
    processor_token_create_request.account_id = plaid_account_id
    stripe_response = plaid_client.processor_stripe_bank_account_token_create(processor_token_create_request)
    bank_account_token = stripe_response.stripe_bank_account_token
    self.stripe_token = bank_account_token
    self.verified = true
  end

  def plaid_client
    unless @plaid_client
      environment = Rails.env.production? ? 'production' : 'sandbox'
      configuration = Plaid::Configuration.new
      configuration.server_index = Plaid::Configuration::Environment[environment]
      configuration.api_key["PLAID-CLIENT-ID"] = ENV['PLAID_CLIENT_ID']
      configuration.api_key["PLAID-SECRET"] = ENV['PLAID_SECRET']
      api_client = Plaid::ApiClient.new(configuration)
      @plaid_client = Plaid::PlaidApi.new(api_client)
    end
    @plaid_client
  end
end
