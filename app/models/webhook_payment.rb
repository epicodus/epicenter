class WebhookPayment < Webhook
  def initialize(attributes)
    if attributes[:event_name]
      @payload = PaymentSerializer.new(attributes[:payment]).as_json.merge({ event_name: attributes[:event_name] })
    else
      @payload = PaymentSerializer.new(attributes[:payment]).as_json
    end
    @payload[:end_date] = attributes[:end_date] if attributes[:end_date]
    @endpoint = ENV['ZAPIER_PAYMENT_WEBHOOK_URL']
    super()
  end
end
