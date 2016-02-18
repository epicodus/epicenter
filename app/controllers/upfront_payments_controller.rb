class UpfrontPaymentsController < ApplicationController
  authorize_resource :payment

  def create
    @payment = current_student.make_upfront_payment
    if @payment.persisted?
      redirect_to student_payments_path(current_student), notice: "Thank You! Your upfront payment has been made."
    else
      @payments = current_student.payments
      render 'payments/index'
    end
  end
end
