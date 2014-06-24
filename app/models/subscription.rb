class Subscription < ActiveRecord::Base
  Balanced.configure(ENV['BALANCED_API_KEY'])

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user

  after_create :create_verification

private
  def create_verification
    bank_account = Balanced::BankAccount.fetch(account_uri)
    verification = bank_account.verify
    self.verification_uri = verification.href
  end

  # def verify_account(current_user)
  #   verification = Balanced::BankAccountVerification.fetch(current_user.verification_uri)
  #   verification_response = verification.confirm(amount_1 = first_deposit, amount_2 = second_deposit)
  #   verification_response.verification_status == "succeeded"
  # end

  def start_recurring_payments
  end
end
