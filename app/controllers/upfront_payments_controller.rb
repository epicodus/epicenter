class UpfrontPaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @payment = current_user.make_upfront_payment
    if @payment.persisted?
      flash[:notice] = "Thank You! Your upfront payment has been made."
      redirect_to payments_path
    else
      @payments = current_user.payments
      render 'payments/index'
    end
  end
end
