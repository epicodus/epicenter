class InviteMailer < Devise::Mailer

  def student_invitation_instructions(record, opts={})
    devise_mail(record, :student_invitation_instructions, opts)
  end

  def admin_invitation_instructions(record, opts={})
    devise_mail(record, :admin_invitation_instructions, opts)
  end

  # this moves the Devise template path from /views/devise/mailer to /views/invite_mailer/
  def headers_for(action, opts)
      super.merge!({template_path: '/invite_mailer/'})
  end

end
