class Users::SessionsController < Devise::SessionsController

  def create
    user = User.find_by(email: params[:user][:email])
    if user.valid_password?(params[:user][:password])
      if user.is_a? Admin
        request.env["devise.mapping"] = Devise.mappings[:admin]
      elsif user.is_a? Student
        request.env["devise.mapping"] = Devise.mappings[:student]
      end
      sign_in user
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      super
    end
  end
end
