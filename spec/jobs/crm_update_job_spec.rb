require 'rails_helper'

RSpec.describe CrmUpdateJob, type: :job do
  it "matches with enqueued job" do
    ActiveJob::Base.queue_adapter = :test
    expect {
      CrmUpdateJob.perform_later
    }.to have_enqueued_job(CrmUpdateJob)
  end
end
