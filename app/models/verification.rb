class Verification
  include ActiveModel::Model
  attr_accessor :first_deposit, :second_deposit

  def initialize(params={})
    @subscription = params[:subscription]
    unless @subscription.nil?
      @bank_account = Balanced::BankAccount.fetch(@subscription.account_uri)
    end
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
    rescue Balanced::BankAccountVerificationFailure => exception
      errors.add(:base, exception.description)
      false
    end
  end
end
