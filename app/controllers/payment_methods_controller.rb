class PaymentMethodsController < ApplicationController
  before_filter :authenticate_student!

  def new
    if params.has_key?(:sig_id)
      enrollment_agreement_signature = Signature.find_by(signature_request_id: params[:sig_id])
      enrollment_agreement_signature.update(is_complete: true)
    end
  end

  def index
    @payment_methods = current_user.payment_methods_primary_first_then_pending
    @primary_payment_method = current_user.primary_payment_method
  end
end
