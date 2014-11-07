class PaymentsController < ApplicationController
  authorize_resource
  before_filter :ensure_student_has_primary_payment_method

  def index
    @payments = current_student.payments
    if current_student.upfront_payment_due?
      @payment = Payment.new(amount: current_student.upfront_amount_with_fees)
    else
      @payment = Payment.new(amount: current_student.recurring_amount_with_fees)
    end
  end

private
  def ensure_student_has_primary_payment_method
    redirect_to payment_methods_path if !current_student.primary_payment_method
  end
end
