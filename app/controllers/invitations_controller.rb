class InvitationsController < Devise::InvitationsController

  def create
    if params[:student_id]
      resend_invitation
    else
      email = params[:student][:email]
      if User.find_by(email: email)
        redirect_to new_student_invitation_path, alert: "Email already used in Epicenter"
      else
        WebhookInvite.new(email: email)
        redirect_to root_path, notice: "An invitation has been initiated for #{email}"
      end
    end
  end

private

  def resend_invitation
    student = Student.find(params[:student_id])
    student.invite!
    redirect_to root_path, notice: "A new invitation email has been sent to #{student.email}"
  end
end
