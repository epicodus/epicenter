class AttendanceSignInController < ApplicationController

  def create
    params[:email1] = params[:email1].downcase
    if is_weekday? && IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      if params[:email2] == ""
        sign_in_solo_student
      else
        sign_in_pair
      end
    else
      fail('Attendance sign in unavailable.')
    end
  end

private

  def sign_in_solo_student
    student = User.find_by(email: params[:email1])
    if valid_credentials(student, params[:password1])
      record = AttendanceRecord.find_or_initialize_by(student: student, date: Time.zone.now.to_date)
      record.station = params[:station]
      record.save
      if Time.zone.now.to_date.friday?
        redirect_to welcome_path, notice: "Welcome #{student.name}. Your sign in time has been recorded."
      else
        redirect_to welcome_path, alert: "Welcome #{student.name}. <strong>Your sign in time has been recorded, but you are signed in without a pair.</strong><br>Sign in again at <a href='/sign_in'>epicenter.epicodus.com/sign_in</a> to record your pair. (Doing so will not affect your sign in time.)"
      end
    else
      fail('Invalid email or password.')
    end
  end

  def sign_in_pair
    params[:email2] = params[:email2].downcase
    student_1 = User.find_by(email: params[:email1])
    student_2 = User.find_by(email: params[:email2])
    if student_1 != student_2 && valid_credentials(student_1, params[:password1]) && valid_credentials(student_2, params[:password2])
      sign_in_pairs_with_valid_credentials(student_1, student_2)
    else
      fail('Invalid login credentials.')
    end
  end

  def valid_credentials(user, password)
    user.try(:valid_password?, password)
  end

  def sign_in_pairs_with_valid_credentials(student_1, student_2)
    record_1 = AttendanceRecord.find_or_initialize_by(student: student_1, date: Time.zone.now.to_date)
    record_2 = AttendanceRecord.find_or_initialize_by(student: student_2, date: Time.zone.now.to_date)
    record_1.station = params[:station]
    record_2.station = params[:station]
    record_1.pair_id = student_2.id
    record_2.pair_id = student_1.id
    if record_1.save && record_2.save
      redirect_to welcome_path, notice: "Welcome #{student_1.name} and #{student_2.name}. Your attendance records have been created."
    else
      fail('There was a problem saving attendance records. Please notify a teacher.')
    end
  end

  def fail(message)
    redirect_to sign_in_path, alert: message
  end
end
