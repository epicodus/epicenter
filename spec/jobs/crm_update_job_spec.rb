require 'rails_helper'

RSpec.describe CrmUpdateJob, :vcr, type: :job do
  include ActiveJob::TestHelper

  let(:student) { FactoryBot.create(:user_with_all_documents_signed, email: 'example@example.com') }
  let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
  let(:lead_id) { get_lead_id(student.email) }
  let(:contact_id) { close_io_client.find_lead(lead_id)['contacts'].first['id'] }

  before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
    close_io_client.update_lead(lead_id, { 'custom.Class': nil })
    close_io_client.update_contact(contact_id, Hashie::Mash.new({ type: "office", email: student.email }))
  end

  it "matches with enqueued job" do
    ActiveJob::Base.queue_adapter = :test
    expect {
      CrmUpdateJob.perform_later
    }.to have_enqueued_job(CrmUpdateJob)
  end

  it "executes perform for updating lead" do
    update_fields = { Rails.application.config.x.crm_fields['AMOUNT_PAID'] => '100' }
    expect_any_instance_of(Closeio::Client).to receive(:update_lead).with(lead_id, update_fields)
    perform_enqueued_jobs { CrmUpdateJob.perform_later(lead_id, update_fields) }
  end

  it "executes perform for updating contact" do
    expect_any_instance_of(Closeio::Client).to receive(:update_contact).with(contact_id, {:emails=>[{"type"=>"office", "email"=>"second-email@example.com"}, {"type"=>"office", "email"=>"example@example.com"}]})
    perform_enqueued_jobs { CrmUpdateJob.perform_later(lead_id, email: "second-email@example.com") }
  end

  it "executes perform for creating note" do
    expect_any_instance_of(Closeio::Client).to receive(:create_note).with({:lead_id=>lead_id, :note=>"test note"})
    perform_enqueued_jobs { CrmUpdateJob.perform_later(lead_id, note: "test note") }
  end
end
