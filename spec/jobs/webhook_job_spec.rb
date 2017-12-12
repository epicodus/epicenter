require 'rails_helper'

RSpec.describe WebhookJob, type: :job do
  include ActiveJob::TestHelper

  it "matches with enqueued job" do
    ActiveJob::Base.queue_adapter = :test
    expect {
      WebhookJob.perform_later
    }.to have_enqueued_job(WebhookJob)
  end

  it 'sends webhook via ActiveJob', :stripe_mock, :stub_mailgun, :vcr do
    student = FactoryBot.create(:user_with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
    webhook = WebhookPayment.new({ payment: payment })
    allow(Webhook).to receive(:send).and_return({})
    expect(Webhook).to receive(:send).with(webhook.endpoint, webhook.payload)
    perform_enqueued_jobs { WebhookJob.perform_later(webhook.endpoint, webhook.payload) }
  end
end
