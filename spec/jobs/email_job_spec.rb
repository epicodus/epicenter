require 'rails_helper'

RSpec.describe EmailJob, type: :job do
  include ActiveJob::TestHelper

  before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "matches with enqueued job" do
    ActiveJob::Base.queue_adapter = :test
    expect {
      EmailJob.perform_later
    }.to have_enqueued_job(EmailJob)
  end

  it "executes perform for sending email via mailgun" do
    mailgun_client = spy("mailgun client")
    allow(Mailgun::Client).to receive(:new) { mailgun_client }
    fields = { :from => ENV['FROM_EMAIL_REVIEW'], :to => "example@example.com", :subject => "test subject", :text => "test body" }
    expect(mailgun_client).to receive(:send_message).with(ENV['MAILGUN_DOMAIN'], fields)
    perform_enqueued_jobs { EmailJob.perform_later(fields) }
  end
end
