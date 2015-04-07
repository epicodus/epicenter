class InvitationsController < Devise::InvitationsController

#After an invitation is created and sent, the inviter will be redirected to this path (rather than the
#after_sign_in_path_for within the Application Controller).
  def after_invite_path_for(user)
    root_path
  end

end
