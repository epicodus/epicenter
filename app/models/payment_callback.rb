class PaymentCallback
  include ActiveModel::Model

  def initialize(params)
    payment = Payment.find_by_id(params['paymentId']) || raise(PaymentError, "Unable to find payment #{params['paymentId']} in response to Zapier callback.")
    txnID = params['txnID'] || raise(PaymentError, "Unable to find QBO txnID for payment #{payment.id} in response to Zapier callback.")
    payment.update_columns(qbo_journal_entry_ids: payment.qbo_journal_entry_ids << txnID)
  end
end
