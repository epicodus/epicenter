class Payment < ActiveRecord::Base
  Balanced.configure(ENV['BALANCED_API_KEY'])

  belongs_to :subscription
  validates_presence_of :amount, :subscription_id

  before_create :make_payment

private
  def make_payment
    begin
      bank_account = Balanced::BankAccount.fetch(subscription.account_uri)

      debit = bank_account.debit(
        :amount => amount,
        :appears_on_statement_as => 'Epicodus Tuition',
        :description => 'Some descriptive text for the debit in the dashboard'
      )
      self.payment_uri = debit.href if !debit.failure_reason
    rescue
      false
    end
  end
end
