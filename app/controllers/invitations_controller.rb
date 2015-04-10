class InvitationsController < Devise::InvitationsController
  #After an invitation is created and sent, the inviter will be redirected to this path (rather than the
  #after_sign_in_path_for within the Application Controller).
  def after_invite_path_for(user)
    root_path
  end

  def create
    @invited_user = User.invite!(invite_params, current_inviter) do |u|
      # Skip sending the default Devise Invitable e-mail
      u.skip_invitation = true
    end
    # Set the value for :invitation_sent_at because we skip calling the Devise Invitable method deliver_invitation which normally sets this value
    @invited_user.update_attribute :invitation_sent_at, Time.now.utc unless @invited_user.invitation_sent_at
    # Use our own mailer to send the invitation e-mail
    if InviteMailer.invite_email(@invited_user, current_user).deliver
      flash[:notice] = "You successfully invited #{@invited_user.email}"
      redirect_to root_path
    else
      flash[:alert] = 'Your invitation did not send'
      render new
    end
  end

end
