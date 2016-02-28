class OmniauthCallbacksController < ApplicationController

  def create
    response = request.env['omniauth.auth']
    user = User.find_by(email: response[:info][:email])
    if user.try(:authenticate_with_github, response[:uid])
      sign_in user
      redirect_to root_path, notice: 'Signed in successfully.'
      if is_local? && user.is_a?(Student)
        @attendance_record = AttendanceRecord.new(student: user)
        @attendance_record.sign_in_ip_address = request.env['HTTP_CF_CONNECTING_IP']
        @attendance_record.save
      end
    else
      redirect_to root_path, alert: 'Your GitHub and Epicenter credentials do not match.'
    end
  end
end
