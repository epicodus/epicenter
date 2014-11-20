class RecurringPaymentsController < ApplicationController
  authorize_resource :payment

  def create
    @payment = current_student.start_recurring_payments
    if @payment.persisted?
      redirect_to payments_path, notice: "Thank You! Your first recurring payment has been made."
    else
      @payments = current_student.payments
      render 'payments/index'
    end
  end
end
