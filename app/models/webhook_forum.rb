class WebhookForum < Webhook
  def initialize(attributes)
    @method = 'PUT'
    @payload = {}
    @endpoint = "https://forum.epicodus.com/admin/users/#{attributes[:id]}/anonymize?api_username=michael&api_key=#{ENV['FORUM_API_KEY']}"
    super()
  end
end
