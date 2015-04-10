class InviteMailer < Devise::Mailer

  def headers_for(action, opts)
    super.merge!({template_path: '/invite_mailer'})
  end

  def invite_email(invited_user, current_invitor)
    @invited_user = invited_user
    @current_invitor = current_invitor
    @token = @invited_user.invitation_token
    mail(to: @invited_user.email,
    from: "students@epicodus.com",
    subject: "Invitation to Epicenter",
    layout: "invite_email")
  end

end
