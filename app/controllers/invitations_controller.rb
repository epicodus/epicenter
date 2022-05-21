class InvitationsController < Devise::InvitationsController
  
  def create
    if params[:student_id]
      resend_invitation
    else
      email = params[:student][:email]
      if User.find_by(email: email)
        redirect_to new_student_invitation_path, alert: "Email already used in Epicenter"
      else
        student = Student.invite(email: email)
        redirect_to root_path, notice: "#{email} has been invited to Epicenter but NOT subscribed to welcome sequence (#{view_context.link_to('view', student_courses_path(student)).html_safe})"
      end
    end
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
