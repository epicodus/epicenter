class DemographicsController < ApplicationController
  include SignatureUpdater

  before_filter :authenticate_student!

  def new
    update_signature_request
  end

  def create
    Demographics.create(current_student, params[:demographics])
    redirect_to payment_methods_path
  end
end
