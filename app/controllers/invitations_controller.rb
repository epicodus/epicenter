class InvitationsController < Devise::InvitationsController

  def after_invite_path_for(user)
    if user.is_a? Admin
      cohort_assessments_path(user.current_cohort)
    elsif user.is_a? Student
      user.class_in_session? ? cohort_assessments_path(user.cohort) : proper_payments_path(user)
    end
  end

end
