class BalancedEvent
  include ActiveModel::Model

  def initialize(params)
    params["events"].each do |event|
      check_event_type(event)
    end
  end

private
  def check_event_type(event)
    if event["type"] == "debit.succeeded"
      update_payment_status(event, "succeeded")
    elsif event["type"] == "debit.failed"
      update_payment_status(event, "failed")
    end
  end

  def update_payment_status(event, status)
    payment = Payment.find_by_payment_uri(payment_uri(event))
    payment.update(status: status) if payment
  end

  def payment_uri(event)
    event['entity']['debits'][0]['href']
  end
end

# event type
# params["events"][0]["type"]
# "debit.created", "debit.succeeded", "debit.failed"

# debit status
# params["events"][0]['entity']['debits'][0]['status']
# "succeeded", "pending", "failed"

# debit href
# params["events"][0]['entity']['debits'][0]['href']

# failure reason
# params["events"][0]['entity']['debits'][0]['failure_reason']
