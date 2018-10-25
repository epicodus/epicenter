class InvitationCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]

    if CrmLead.lead_exists?(email)
      crm_lead = CrmLead.new(email)
    else
      Rails.logger.info "Invitation callback error: unique CRM lead not found for #{email}"
      raise CrmError, "Invitation callback: unique CRM lead not found for #{email}"
    end

    if User.exists?(email: email)
      existing_student = Student.with_deleted.find_by(email: email)
      if existing_student.payments.empty? && existing_student.attendance_records.empty?
        existing_student.really_destroy!
      else
        Rails.logger.info "Invitation callback error: #{email} already exists in Epicenter"
        raise CrmError, "Invitation callback: #{email} already exists in Epicenter"
      end
    end

    Rails.logger.info "Invitation callback: beginning invitation"
    student = Student.invite!(email: email, name: crm_lead.name, course: crm_lead.cohort.courses.first) do |u|
      u.skip_invitation = true
    end
    crm_lead.cohort.courses.each do |course|
      if course.internship_course? && !crm_lead.work_eligible?
        student.courses << Course.find_by(description: 'Internship Exempt')
      else
        student.courses << course unless student.courses.include?(course)
      end
    end
    student.update(office: student.course.office)
    crm_lead.update({ 'custom.Epicenter - Raw Invitation Token': student.raw_invitation_token, 'custom.Epicenter - ID': student.id })
    Rails.logger.info "Invitation callback: completing invitation"
  end
end
