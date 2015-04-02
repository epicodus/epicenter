class InvitationsController < Devise::InvitationsController

  def after_invite_path_for(user)
    root_path
  end

end
