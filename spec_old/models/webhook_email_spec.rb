describe WebhookEmail do
  before { allow(Webhook).to receive(:send).and_return({}) }

  it 'creates webhook with endpoint' do
    webhook = WebhookEmail.new({ email: 'example@example.com', subject: 'test email', body: 'test body' })
    expect(webhook.endpoint).to eq ENV['ZAPIER_EMAIL_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookEmail.new({ email: 'example@example.com', subject: 'test email', body: 'test body' })
    expect(webhook.payload).to eq ({ email: 'example@example.com', subject: 'test email', body: 'test body', auth: ENV['ZAPIER_SECRET_TOKEN'] })
  end
end
