class WebhookCreateTask < Webhook
  def initialize(attributes)
    @payload = attributes
    @endpoint = ENV['ZAPIER_CREATE_TASK_WEBHOOK_URL']
    super()
  end
end
