class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :payment_method, polymorphic: true

  validates_presence_of :amount, :user_id
  validates :payment_method, presence: true

  before_create :make_payment

private
  def make_payment
    payment_method = user.primary_payment_method
    debit = payment_method.fetch_balanced_account.debit(
      :amount => amount,
      :appears_on_statement_as => 'Epicodus tuition'
    )
    self.payment_uri = debit.href if !debit.failure_reason
  end
end
