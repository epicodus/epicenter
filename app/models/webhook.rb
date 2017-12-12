class Webhook
  attr_reader :endpoint, :payload

  def initialize
    WebhookJob.perform_later(endpoint, payload)
  end

  def self.send(endpoint, payload)
    response = RestClient.post(endpoint, payload.to_json, {content_type: :json, accept: :json})
    raise response.to_s if response.code >= 400
    response
  end
end
