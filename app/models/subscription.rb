class Subscription
  include ActiveModel::Model

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :first_deposit, :second_deposit

  def verify_account
    false
  end

  def start_recurring_payments
  end
end
