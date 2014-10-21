class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @payments = current_user.payments.reload
    if current_user.upfront_payment_due?
      upfront_amount = current_user.primary_payment_method.calculate_charge(current_user.plan.upfront_amount)
      @payment = Payment.new(amount: upfront_amount)
    else
      recurring_amount = current_user.primary_payment_method.calculate_charge(current_user.plan.recurring_amount)
      @payment = Payment.new(amount: recurring_amount)
    end
  end
end
