describe Webhook do
  let(:student) { FactoryBot.create(:student_with_credit_card) }
  let(:payment) { FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00) }

  it 'sends webhook', :stripe_mock, :stub_mailgun, :vcr, :dont_stub_webhook do
    webhook = WebhookPayment.new({ payment: payment })
    response = Webhook.send({ method: webhook.method, endpoint: webhook.endpoint, payload: webhook.payload })
    expect(response.code).to eq 200
  end

  it 'sends webhook with method PUT', :vcr, :dont_stub_webhook do
    response = double
    allow(response).to receive(:code).and_return(200)
    allow(RestClient).to receive(:put).and_return(response)
    webhook = WebhookForum.new({ id: 999999 })
    response = Webhook.send({ method: webhook.method, endpoint: webhook.endpoint, payload: webhook.payload })
    expect(response.code).to eq 200
  end
end
