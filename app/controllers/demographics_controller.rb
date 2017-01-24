class DemographicsController < ApplicationController
  include SignatureUpdater

  before_filter :authenticate_student!

  def new
    update_signature_request
    @demographic_info = DemographicInfo.new
  end

  def create
    demographic_info = DemographicInfo.new(current_student, demographic_info_params)
    if demographic_info.save
      redirect_to payment_methods_path
    else
      redirect_to payment_methods_path, alert: "Unable to save demographics info."
    end
  end

private
  def demographic_info_params
    params.require(:demographic_info).permit(:age, :job, :salary, :education, :veteran, :genders => [], :races => [])
  end
end
