describe WebhookPayment do
  let(:student) { FactoryBot.create(:student, :with_pt_intro_cohort) }
  let(:payment) { FactoryBot.create(:payment, student: student, offline: true, amount: 600_00) }

  it 'creates webhook with endpoint' do
    webhook = WebhookPayment.new({ payment: payment })
    expect(webhook.endpoint).to eq ENV['ZAPIER_PAYMENT_WEBHOOK_URL']
  end

  it 'creates webhook with payload' do
    webhook = WebhookPayment.new({ payment: payment })
    expect(webhook.payload).to eq PaymentSerializer.new(payment).as_json
  end

  it 'creates webhook with payload that includes event_name when provided' do
    webhook = WebhookPayment.new({ event_name: 'test', payment: payment })
    expect(webhook.payload).to eq PaymentSerializer.new(payment).as_json.merge({ event_name: 'test' })
  end

  it 'overrides end_date if end_date included in params' do
    webhook = WebhookPayment.new({ event_name: 'test', payment: payment, end_date: 'test-end-date' })
    expect(webhook.payload[:end_date]).to eq 'test-end-date'
  end
end
