class PaymentCallback
  include ActiveModel::Model

  def initialize(params)
    payment = Payment.find_by_id(params['paymentId']) || raise(PaymentError, "Unable to find payment #{params['paymentId']} in response to Zapier callback.")
    doc_number = params['docNumber'] || raise(PaymentError, "Unable to find doc_number for payment #{payment.id} in response to Zapier callback.")
    payment.update_columns(qbo_doc_numbers: payment.qbo_doc_numbers << doc_number)
  end
end
