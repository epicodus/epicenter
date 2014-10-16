class Payment < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :amount, :user_id

  before_create :make_payment

private
  def make_payment
    balanced_bank_account = Balanced::BankAccount.fetch(user.bank_account.account_uri)
    debit = balanced_bank_account.debit(
      :amount => amount,
      :appears_on_statement_as => 'Epicodus tuition'
    )
    self.payment_uri = debit.href if !debit.failure_reason
  end
end
