class RegistrationsController < Devise::RegistrationsController

  def new
    if request.env["devise.mapping"] == Devise.mappings[:company] && !current_user
      super
    else
      redirect_to root_path, alert: 'Sign up is only allowed via invitation.'
    end
  end

  def update
    if current_student && params[:student][:email] != current_student.email && current_student.valid_password?(params[:student][:current_password])
      if params[:student][:email].match(/\A(\S+)@(.+)\.(\S+)\z/)
        current_student.crm_lead.update(email: params[:student][:email])
      else
        redirect_to edit_student_registration_path, alert: "Invalid email address." and return
      end
    end
    super
  end
end
