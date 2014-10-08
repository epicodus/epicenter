class UpfrontPaymentsController < ApplicationController
  before_action :authenticate_user!

  def new
    @payment = Payment.new(amount: current_user.plan.upfront_amount)
  end

  def create
    current_user.bank_account.make_upfront_payment
    flash[:notice] = "Thank You! Your upfront payment has been made."
    redirect_to payments_path
  end
end
