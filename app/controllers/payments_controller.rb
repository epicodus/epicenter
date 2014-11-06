class PaymentsController < ApplicationController
  authorize_resource
  
  def index
    @payments = current_student.payments
    if current_student.upfront_payment_due?
      @payment = Payment.new(amount: current_student.upfront_amount_with_fees)
    else
      @payment = Payment.new(amount: current_student.recurring_amount_with_fees)
    end
  end
end
