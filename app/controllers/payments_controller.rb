class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @payments = current_user.payments
    if current_user.upfront_payment_due?
      upfront_amount = current_user.plan.upfront_amount
      upfront_amount_with_fees = upfront_amount + current_user.primary_payment_method.calculate_fee(upfront_amount)
      @payment = Payment.new(amount: upfront_amount_with_fees)
    else
      recurring_amount = current_user.plan.recurring_amount
      recurring_amount_with_fees = recurring_amount + current_user.primary_payment_method.calculate_fee(recurring_amount)
      @payment = Payment.new(amount: recurring_amount_with_fees)
    end
  end
end
