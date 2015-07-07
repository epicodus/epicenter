class PaymentMethodsController < ApplicationController
  include SignatureUpdater

  before_filter :authenticate_student!

  def new
    update_signature_request
  end

  def index
    @payment_methods = current_user.payment_methods_primary_first_then_pending
    @primary_payment_method = current_user.primary_payment_method
  end
end
