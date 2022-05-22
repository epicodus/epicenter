class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github

  def github
    response = request.env['omniauth.auth']
    user = User.find_by(email: response[:info][:email])
    if user.try(:authenticate_with_github, response[:uid])
      sign_in user
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      redirect_to root_path, alert: 'Your GitHub and Epicenter credentials do not match.'
    end
  end

  def failure
    redirect_to root_path, alert: 'There was a problem logging in with GitHub.'
  end
end
