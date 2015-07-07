class PaymentMethodsController < ApplicationController
  include SignatureParamsHelper

  before_filter :authenticate_student!

  def new
    check_signature_params
  end

  def index
    @payment_methods = current_user.payment_methods_primary_first_then_pending
    @primary_payment_method = current_user.primary_payment_method
  end
end
