class RecurringPaymentsOptionController < ApplicationController
  include SignatureUpdater

  def index
    update_signature_request
  end
end
