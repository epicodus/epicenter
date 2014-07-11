class Verification < Balanced::BankAccountVerification

  def initialize(subscription)
    bank_account = Balanced::BankAccount.fetch(subscription.account_uri)
    verification = bank_account.verify
    subscription.verification_uri = verification.href
  end
end
