class RecurringPaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @payment = current_user.start_recurring_payments
    if @payment.persisted?
      flash[:notice] = "Thank You! Your first recurring payment has been made."
      redirect_to payments_path
    else
      @payments = current_user.payments
      render 'payments/index'
    end
  end
end
