require 'rails_helper'

RSpec.describe EmailJob, type: :job do
  it "matches with enqueued job" do
    ActiveJob::Base.queue_adapter = :test
    expect {
      EmailJob.perform_later
    }.to have_enqueued_job(EmailJob)
  end
end
