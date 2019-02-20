class InvitationCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]

    if User.exists?(email: email)
      existing_student = Student.with_deleted.find_by(email: email)
      if existing_student.payments.empty? && existing_student.attendance_records.empty?
        existing_student.really_destroy
      else
        Rails.logger.info "Invitation callback error: #{email} already exists in Epicenter"
        raise CrmError, "Invitation callback: #{email} already exists in Epicenter"
      end
    end

    Rails.logger.info "Invitation callback: creating Epicenter account"
    student = Student.invite(email: email)

    Rails.logger.info "Invitation callback: Subscribing to email sequence"
    student.crm_lead.subscribe_to_welcome_email_sequence
  end
end
