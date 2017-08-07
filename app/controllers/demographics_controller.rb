class DemographicsController < ApplicationController
  include SignatureUpdater

  before_action :authenticate_student!

  def new
    update_signature_request
    @demographic_info = DemographicInfo.new
  end

  def create
    @demographic_info = DemographicInfo.new(current_student, demographic_info_params)
    if @demographic_info.save
      current_student.update(demographics: true)
      redirect_to payment_methods_path
    else
      render :new
    end
  end

private
  def demographic_info_params
    params.require(:demographic_info).permit(:age, :job, :pronouns, :salary, :education, :veteran, :genders => [], :races => [])
  end
end
