class InvitationCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]

    unless CrmLead.lead_exists?(email)
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
    Student.invite(email: email)
    Rails.logger.info "Invitation callback: completing invitation"
  end
end
