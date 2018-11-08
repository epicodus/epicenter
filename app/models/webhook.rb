class Webhook
  attr_reader :method, :endpoint, :payload

  def initialize
    WebhookJob.perform_later({ method: method, endpoint: endpoint, payload: payload })
  end

  def self.send(attributes)
    if attributes[:method] == 'PUT'
      response = RestClient.put(attributes[:endpoint], attributes[:payload].to_json, {content_type: :json, accept: :json})
    else
      response = RestClient.post(attributes[:endpoint], attributes[:payload].to_json, {content_type: :json, accept: :json})
    end
    raise response.to_s if response.code >= 400
    response
  end
end
