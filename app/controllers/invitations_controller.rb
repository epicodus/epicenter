class InvitationsController < Devise::InvitationsController
  
  def create
    resend_invitation if params[:student_id]
  end

  def update
    cookies[:setup_2fa] = {value: 'true', expires: 1.month} if params['setup_2fa'] == 'true'
    super
  end

private

  def resend_invitation
    student = Student.find(params[:student_id])
    student.invite!
    redirect_to root_path, notice: "A new invitation email has been sent to #{student.email}"
  end
end
