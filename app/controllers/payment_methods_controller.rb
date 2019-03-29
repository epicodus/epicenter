class PaymentMethodsController < ApplicationController
  before_action :authenticate_student!

  def index
    @payment_methods = current_user.payment_methods_primary_first_then_pending
    redirect_to new_payment_method_path if @payment_methods.empty?
    @primary_payment_method = current_user.primary_payment_method
  end
end
