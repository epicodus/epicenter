class RecurringPaymentsController < ApplicationController
  before_action :authenticate_user!

  def new
    @payment = Payment.new(amount: current_user.plan.recurring_amount)
  end

  def create
    current_user.bank_account.start_recurring_payments
    flash[:notice] = "Thank You! Your first recurring payment has been made."
    redirect_to payments_path
  end
end
