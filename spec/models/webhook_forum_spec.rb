describe WebhookForum do
  it 'creates webhook with PUT method' do
    webhook = WebhookForum.new({ id: 9999 })
    expect(webhook.method).to eq 'PUT'
  end

  it 'creates webhook with endpoint' do
    webhook = WebhookForum.new({ id: 9999 })
    expect(webhook.endpoint).to eq "https://forum.epicodus.com/admin/users/9999/anonymize?api_username=michael&api_key=#{ENV['FORUM_API_KEY']}"
  end
end
