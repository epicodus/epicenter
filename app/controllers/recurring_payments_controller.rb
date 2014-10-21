class RecurringPaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.start_recurring_payments
    flash[:notice] = "Thank You! Your first recurring payment has been made."
    redirect_to payments_path
  end
end
