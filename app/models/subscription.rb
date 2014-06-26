class Subscription < ActiveRecord::Base
  Balanced.configure(ENV['BALANCED_API_KEY'])

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user

  before_create :create_verification

  before_update :confirm_verification, if: :confirming_account?

  def create_verification
    bank_account = Balanced::BankAccount.fetch(account_uri)
    verification = bank_account.verify
    self.verification_uri = verification.href
  end

  def confirm_verification
    begin
      puts "#{verification_uri}"
      verification = Balanced::BankAccountVerification.fetch(verification_uri)
      puts "made it past fetch"
      verification_response = verification.confirm(first_deposit, second_deposit)
      puts "made it past response"
      self.verified = true if verification_response.verification_status == "succeeded"
    rescue
      puts "in rescue"
      false
    end
  end

private
  def confirming_account?
    first_deposit && second_deposit
  end
end
