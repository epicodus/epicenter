class InvitationCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]
    existing_student = Student.with_deleted.find_by(email: email)
    if existing_student.try(:payments).try(:any?) || existing_student.try(:attendance_records).try(:any?)
      existing_student.crm_lead.create_task("Unable to invite due to existing Epicenter account")
    else
      existing_student.try(:really_destroy)
      student = Student.invite(email: email)
      student.crm_lead.subscribe_to_welcome_email_sequence
    end
  end
end
