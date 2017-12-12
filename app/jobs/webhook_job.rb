class WebhookJob < ApplicationJob
  queue_as :default

  def perform(endpoint, payload)
    Webhook.send(endpoint, payload)
  end
end
