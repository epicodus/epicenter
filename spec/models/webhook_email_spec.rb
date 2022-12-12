describe WebhookEmail do
  before { allow(Webhook).to receive(:send).and_return({}) }

  it 'creates webhook with endpoint' do
    webhook = WebhookEmail.new({ lead_id: 'test_lead_id', text: 'test email' })
    expect(webhook.endpoint).to eq ENV['ZAPIER_EMAIL_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookEmail.new({ lead_id: 'test_lead_id', text: 'test email' })
    expect(webhook.payload).to eq ({ lead_id: 'test_lead_id', text: 'test email', auth: ENV['ZAPIER_SECRET_TOKEN'] })
  end
end
