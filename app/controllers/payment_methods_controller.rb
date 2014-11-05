class PaymentMethodsController < ApplicationController
  def index
    @payment_methods = current_user.payment_methods_primary_first
    @primary_payment_method = current_user.primary_payment_method
  end
end
