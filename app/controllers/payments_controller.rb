class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @payments = current_user.payments
    if current_user.upfront_payment_due?
      @payment = Payment.new(amount: current_user.upfront_amount_with_fees)
    else
      @payment = Payment.new(amount: current_user.recurring_amount_with_fees)
    end
  end
end
