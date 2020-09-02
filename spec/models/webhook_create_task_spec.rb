describe WebhookCreateTask do
  before { allow(Webhook).to receive(:send).and_return({}) }

  it 'creates webhook with endpoint' do
    webhook = WebhookCreateTask.new({ lead_id: 'test_lead_id', text: 'test task', auth: ENV['ZAPIER_SECRET_TOKEN'] })
    expect(webhook.endpoint).to eq ENV['ZAPIER_CREATE_TASK_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookCreateTask.new({ lead_id: 'test_lead_id', text: 'test task', auth: ENV['ZAPIER_SECRET_TOKEN'] })
    expect(webhook.payload).to eq ({ lead_id: 'test_lead_id', text: 'test task', auth: ENV['ZAPIER_SECRET_TOKEN'] })
  end
end
