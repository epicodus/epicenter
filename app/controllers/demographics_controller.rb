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
      if current_student.upfront_payment_due?
        redirect_to payment_methods_path
      else
        redirect_to student_courses_path(current_student)
      end
    else
      @birth_date = @demographic_info.birth_date
      @education = @demographic_info.education
      @shirt = @demographic_info.shirt
      @after_graduation = @demographic_info.after_graduation
      @country = @demographic_info.country
      @demographic_info.after_graduation_explanation.try('gsub!', 'Other: ', '')
      render :new
    end
  end

private
  def demographic_info_params
    params.require(:demographic_info).permit(:birth_date, :disability, :veteran, :education, :cs_degree,
                    :address, :city, :state, :zip, :country, :shirt, :job, :salary, :after_graduation,
                    :after_graduation_explanation, :time_off, :ssn, :genders => [], :races => [])
  end
end
