class RecurringPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_upfront_payment_not_required
  before_action :ensure_account_is_not_recurring_active

  def new
    @payment = Payment.new(amount: current_user.plan.recurring_amount)
  end

  def create
    current_user.bank_account.start_recurring_payments
    flash[:notice] = "Thank You! Your first recurring payment has been made."
    redirect_to payments_path
  end


private
  def ensure_upfront_payment_not_required
    redirect_to new_upfront_payment_path if current_user.upfront_payment_due?
  end

  def ensure_account_is_not_recurring_active
    if current_user.bank_account.recurring_active
      flash[:alert] = "Recurring payments have already started for this account."
      redirect_to root_path
    end
  end
end
