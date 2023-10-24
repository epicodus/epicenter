class DemographicsController < ApplicationController
  include SignatureUpdater

  before_action :authenticate_student!

  def new
    update_signature_request
    @address = current_student.crm_lead.address
    @city = current_student.crm_lead.city
    @state = current_student.crm_lead.state
    @zip = current_student.crm_lead.zip
    @country = current_student.crm_lead.country
    @demographic_info = DemographicInfo.new
  end

  def create
    @demographic_info = DemographicInfo.new(current_student, demographic_info_params)
    if @demographic_info.save
      current_student.update(demographics: true)
      redirect_to after_sign_in_path_for(current_student)
    else
      @birth_date = @demographic_info.birth_date
      @education = @demographic_info.education
      @shirt = @demographic_info.shirt
      @after_graduation = @demographic_info.after_graduation
      @address = @demographic_info.address
      @city = @demographic_info.city
      @state = @demographic_info.state
      @zip = @demographic_info.zip
      @country = @demographic_info.country
      render :new
    end
  end

private
  def demographic_info_params
    params.require(:demographic_info).permit(:birth_date, :disability, :veteran, :education, :cs_degree,
                    :address, :city, :state, :zip, :country, :shirt, :job, :salary, :after_graduation,
                    :time_off, :ssn, :pronouns_blank, :genders => [], :races => [], :pronouns => [])
  end
end
