class WebhookCreateTask < Webhook
  def initialize(attributes)
    @payload = attributes.merge(auth: ENV['ZAPIER_SECRET_TOKEN'])
    @endpoint = ENV['ZAPIER_CREATE_TASK_WEBHOOK_URL']
    super()
  end
end
