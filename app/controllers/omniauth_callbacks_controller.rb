class OmniauthCallbacksController < ApplicationController

  def create
    response = request.env['omniauth.auth']
    user = User.find_by(email: response[:info][:email])
    if user.try(:authenticate_with_github, response[:uid])
      sign_in user
      if is_weekday? && IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip) && user.is_a?(Student) && !user.signed_in_today?
        attendance_record = AttendanceRecord.create(student: user)
        redirect_to welcome_path, notice: 'Signed in successfully and attendance record created.'
      else
        redirect_to root_path, notice: 'Signed in successfully.'
      end
    else
      redirect_to root_path, alert: 'Your GitHub and Epicenter credentials do not match.'
    end
  end
end
