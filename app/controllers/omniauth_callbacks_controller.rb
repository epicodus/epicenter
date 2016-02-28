class OmniauthCallbacksController < ApplicationController

  def create
    response = request.env['omniauth.auth']
    user = User.find_by(email: response[:info][:email])
    if user.try(:authenticate_with_github, response[:uid])
      sign_in user
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      redirect_to root_path, alert: 'Your GitHub and Epicenter credentials do not match.'
    end
  end
end
