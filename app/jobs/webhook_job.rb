class WebhookJob < ApplicationJob
  queue_as :default

  def perform(attributes)
    Webhook.send(attributes)
  end
end
