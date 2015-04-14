class InviteMailer < Devise::Mailer

  def headers_for(action, opts)
    super.merge!({template_path: '/invite_mailer'})
  end

  def invitation_instructions(invited_user, current_invitor)
    @invited_user = invited_user
    @current_invitor = current_invitor
    @token = @invited_user.raw_invitation_token
    if invited_user.type == "Admin"
      @url = accept_admin_invitation_url(invitation_token: @token)
    else invited_user.type == "Student"
      @url = accept_student_invitation_url(invitation_token: @token)
    end
    mail(to: @invited_user.email,
    from: "students@epicodus.com",
    subject: "Invitation to Epicenter",
    layout: "invitation_instructions")
  end

end
