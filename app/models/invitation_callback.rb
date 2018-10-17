class InvitationCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]
    if CrmLead.lead_exists?(email)
      crm_lead = CrmLead.new(email)
      student = Student.invite!(email: email, name: crm_lead.name) do |u|
        u.skip_invitation = true
      end
      crm_lead.cohort.courses.each do |course|
        student.courses << course
      end
      student.update(office: student.course.office)
      crm_lead.update({ 'custom.Epicenter - Raw Invitation Token': student.raw_invitation_token })
    else
      raise CrmError, "Invitation callback: CRM lead not found for #{email}"
    end
  end
end
