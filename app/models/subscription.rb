class Subscription < ActiveRecord::Base
  Balanced.configure(ENV['BALANCED_API_KEY'])

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user

  def verify_account(current_user)
    verification = Balanced::BankAccountVerification.fetch(current_user.verification_uri)
    verification_response = verification.confirm(amount_1 = 1, amount_2 = 1)
    verification_response.verification_status == "succeeded"
  end

  def start_recurring_payments
  end
end
