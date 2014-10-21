class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @payments = current_user.payments
    @payment = Payment.new
    @recurring_amount = current_user.primary_payment_method.calculate_charge(current_user.plan.recurring_amount)
    @upfront_amount = current_user.primary_payment_method.calculate_charge(current_user.plan.upfront_amount)
  end
end
