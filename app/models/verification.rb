class Verification
  include ActiveModel::Model
  attr_accessor :first_deposit, :second_deposit

  def initialize(params={})
    @bank_account = params[:bank_account]
    unless @bank_account.nil?
      @balanced_bank_account = Balanced::BankAccount.fetch(@bank_account.account_uri)
    end
    @first_deposit = clean_deposit_input(params[:first_deposit])
    @second_deposit = clean_deposit_input(params[:second_deposit])
  end

  def create_test_deposits
    verification = @balanced_bank_account.verify
    @bank_account.verification_uri = verification.href
  end

  def confirm
    verification_uri = @bank_account.verification_uri
    verification = Balanced::BankAccountVerification.fetch(verification_uri)
    begin
      verification.confirm(@first_deposit, @second_deposit)
      @bank_account.update!(verified: true)
      ensure_primary_method_exists
      true
    rescue Balanced::BankAccountVerificationFailure => exception
      errors.add(:base, exception.description)
      false
    end
  end

private
  def ensure_primary_method_exists
    @bank_account.student.set_primary_payment_method(@bank_account) if !@bank_account.student.primary_payment_method
  end

  def clean_deposit_input(input)
    input.to_s.split(".").last
  end
end
