class Payment < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :amount, :user_id

  before_create :make_payment

private
  def make_payment
    payment_method = user.primary_payment_method
    debit = payment_method.debit(
      :amount => amount,
      :appears_on_statement_as => 'Epicodus tuition'
    )
    self.payment_uri = debit.href if !debit.failure_reason
  end
end

