class StripeCallback
  include ActiveModel::Model

  def initialize(params)
    event = params
    check_event_type(event)
  end

private

  def check_event_type(event)
    if event["type"] == "charge.succeeded"
      update_payment_status(event, "succeeded")
    elsif event["type"] == "charge.failed"
      update_payment_status(event, "failed")
    end
  end

  def update_payment_status(event, status)
    payment = Payment.find_by(stripe_transaction: stripe_transaction(event))
    payment.try(:update, status: status)
  end

  def stripe_transaction(event)
    event["data"]["object"]["balance_transaction"]
  end
end
