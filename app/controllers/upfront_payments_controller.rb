class UpfrontPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_upfront_payment_is_due

  def new
    @payment = Payment.new(amount: current_user.plan.upfront_amount)
  end

  def create
    current_user.bank_account.make_upfront_payment
    flash[:notice] = "Thank You! Your upfront payment has been made."
    redirect_to payments_path
  end

private
  def ensure_upfront_payment_is_due
    if !current_user.upfront_payment_due?
      flash[:alert] = "There are no upfront payments due on this account."
      redirect_to root_path
    end
  end
end
