class PaymentMethodsController < ApplicationController
  before_action :authenticate_student!

  def index
    @payment_methods = current_user.payment_methods_primary_first_then_pending
    @primary_payment_method = current_user.primary_payment_method
  end
end
