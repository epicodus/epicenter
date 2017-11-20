class CrmUpdateJob < ApplicationJob
  queue_as :default

  def perform(lead_id, update_fields)
    CrmLead.perform_update(lead_id, update_fields)
  end
end
