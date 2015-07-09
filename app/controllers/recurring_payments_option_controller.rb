class RecurringPaymentsOptionController < ApplicationController
  include SignatureUpdater

  before_filter :authenticate_student!

  def index
    update_signature_request
  end
end
