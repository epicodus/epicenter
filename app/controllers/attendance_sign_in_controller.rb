class AttendanceSignInController < ApplicationController

  def create
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
      redirect_to welcome_path, notice: "Welcome #{student.name}. Your attendance record has been created."
    else
      fail('Invalid email or password.')
    end
  end

  def sign_in_pair
    student1 = User.find_by(email: params[:email1])
    student2 = User.find_by(email: params[:email2])
    if student1 != student2 && valid_credentials(student1, params[:password1]) && valid_credentials(student2, params[:password2])
      record1 = AttendanceRecord.find_or_initialize_by(student: student1, date: Time.zone.now.to_date)
      record2 = AttendanceRecord.find_or_initialize_by(student: student2, date: Time.zone.now.to_date)
      if record1 && record2 && record1.student && record2.student # This should always be the case, but is extra check.
        record1.station = params[:station]
        record2.station = params[:station]
        record1.pair_id = student2.id
        record2.pair_id = student1.id
        if record1.save && record2.save
          redirect_to welcome_path, notice: "Welcome #{student1.name} and #{student2.name}. Your attendance records have been created."
        else
          fail('There was a problem saving attendance records. Please notify a teacher.')
        end
      else
        fail('There was a problem initializing attendance records. Please notify a teacher.')
      end
    else
      fail('Invalid login credentials.')
    end

  end

  def valid_credentials(user, pw)
    user.try(:valid_password?, pw)
  end

  def fail(message)
    redirect_to sign_in_path, alert: message
  end

end
