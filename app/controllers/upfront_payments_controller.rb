class UpfrontPaymentsController < ApplicationController
  authorize_resource :payment

  def create
    @payment = current_student.make_upfront_payment
    if @payment.persisted?
      flash[:notice] = "Thank You! Your upfront payment has been made."
      redirect_to payments_path
    else
      @payments = current_student.payments
      render 'payments/index'
    end
  end
end
