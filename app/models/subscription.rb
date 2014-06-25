class Subscription < ActiveRecord::Base
  Balanced.configure(ENV['BALANCED_API_KEY'])

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user

  def create_verification
    bank_account = Balanced::BankAccount.fetch(account_uri)
    verification = bank_account.verify
    self.verification_uri = verification.href
  end

  def confirm_verification
    begin
      verification = Balanced::BankAccountVerification.fetch(verification_uri)
      verification_response = verification.confirm(amount_1 = first_deposit, amount_2 = second_deposit)
      set_verified if verification_response.verification_status == "succeeded"
    rescue
      false
    end
  end

  def start_recurring_payments
  end

private
  def set_verified
    self.verified = true
  end
end
