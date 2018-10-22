class InvitationCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]
    if User.exists?(email: email)
      Rails.logger.info "Invitation callback error: #{email} already exists in Epicenter"
      raise CrmError, "Invitation callback: #{email} already exists in Epicenter"
    elsif !CrmLead.lead_exists?(email)
      Rails.logger.info "Invitation callback error: unique CRM lead not found for #{email}"
      raise CrmError, "Invitation callback: unique CRM lead not found for #{email}"
    else
      Rails.logger.info "Invitation callback: beginning invitation"
      crm_lead = CrmLead.new(email)
      student = Student.invite!(email: email, name: crm_lead.name) do |u|
        u.skip_invitation = true
      end
      crm_lead.cohort.courses.each do |course|
        student.courses << course
      end
      student.update(office: student.course.office)
      crm_lead.update({ 'custom.Epicenter - Raw Invitation Token': student.raw_invitation_token })
      Rails.logger.info "Invitation callback: completing invitation"
    end
  end
end
