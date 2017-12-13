describe Webhook do
  let(:student) { FactoryBot.create(:user_with_credit_card) }
  let(:payment) { FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00) }

  it 'sends webhook', :stripe_mock, :stub_mailgun, :vcr, :dont_stub_webhook do
    webhook = WebhookPayment.new({ payment: payment })
    response = Webhook.send(webhook.endpoint, webhook.payload)
    expect(response.code).to eq 200
  end
end
