class BalancedEvent
  include ActiveModel::Model

  def initialize(params)
    params["events"].each do |event|
      payment_uri = event['entity']['debits'][0]['href']
      if event["type"] == "debit.succeeded"
        # update status of payment to succeeded
      elsif event["type"] == "debit.failed"
        # update status of payment to failed, if exists
      end
    end
  end

  def update_payment_status
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
