class InviteMailer < Devise::Mailer

  def student_invitation_instructions(record, opts={})
    devise_mail(record, :student_invitation_instructions, opts)
  end

  def admin_invitation_instructions(record, opts={})
    devise_mail(record, :admin_invitation_instructions, opts)
  end

end
