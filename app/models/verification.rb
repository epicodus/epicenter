class Verification
  include ActiveModel::Model

  def initialize(params)
    @subscription = params[:subscription] || @subscription = params[:user].subscription
    @bank_account = Balanced::BankAccount.fetch(@subscription.account_uri)
    @first_deposit = params[:first_deposit]
    @second_deposit = params[:second_deposit]
  end

  def create_test_deposits
    verification = @bank_account.verify
    @subscription.verification_uri = verification.href
  end

  def confirm
    verification_uri = @subscription.verification_uri
    verification = Balanced::BankAccountVerification.fetch(verification_uri)
    begin
      verification.confirm(@first_deposit, @second_deposit)
      @subscription.update!(verified: true)
      true
    rescue Balanced::BankAccountVerificationFailure => exception
      errors.add(:base, exception.description)
      false
    end
  end
end
