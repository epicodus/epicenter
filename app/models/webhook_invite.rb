class WebhookInvite < Webhook
  def initialize(attributes)
    @payload = attributes
    @endpoint = ENV['ZAPIER_INVITE_WEBHOOK_URL']
    super()
  end
end
