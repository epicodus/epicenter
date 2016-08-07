class Users::SessionsController < Devise::SessionsController
  before_filter :redirect_if_logged_in

  def create
    params[:user][:email] = params[:user][:email].downcase
    user = User.find_by(email: params[:user][:email])
    if user.try(:valid_password?, params[:user][:password])
      sign_in_admin_or_company_or_student(user)
    else
      super
    end
  end

private

  def redirect_if_logged_in
    redirect_to after_sign_in_path_for(current_user) if current_user
  end

  def sign_in_admin_or_company_or_student(user)
    if user.is_a? Admin
      request.env["devise.mapping"] = Devise.mappings[:admin]
    elsif user.is_a? Company
      request.env["devise.mapping"] = Devise.mappings[:company]
    elsif user.is_a? Student
      request.env["devise.mapping"] = Devise.mappings[:student]
    end
    sign_in user
    redirect_to root_path, notice: 'Signed in successfully.'
  end
end