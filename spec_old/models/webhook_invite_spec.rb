describe WebhookPayment do
  it 'creates webhook with endpoint' do
    webhook = WebhookInvite.new({ email: 'example@example.com' })
    expect(webhook.endpoint).to eq ENV['ZAPIER_INVITE_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookInvite.new({ email: 'example@example.com' })
    expect(webhook.payload).to eq ({ email: 'example@example.com' })
  end
end
