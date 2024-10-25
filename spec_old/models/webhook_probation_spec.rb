describe WebhookProbation do
  before { allow(Webhook).to receive(:send).and_return({}) }

  it 'creates webhook with endpoint' do
    webhook = WebhookProbation.new({ email: 'example@example.com', teacher: 1, advisor: 2 })
    expect(webhook.endpoint).to eq ENV['ZAPIER_PROBATION_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookProbation.new({ email: 'example@example.com', teacher: 1, advisor: 2 })
    expect(webhook.payload).to eq ({ email: 'example@example.com', teacher: 1, advisor: 2, auth: ENV['ZAPIER_SECRET_TOKEN'] })
  end
end
