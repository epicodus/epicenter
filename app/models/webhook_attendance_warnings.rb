class WebhookAttendanceWarnings < Webhook
  def initialize(attributes)
    @payload = attributes.merge(auth: ENV['ZAPIER_SECRET_TOKEN'])
    @endpoint = ENV['ZAPIER_ATTENDANCE_WARNINGS_WEBHOOK_URL']
    super()
  end
end
