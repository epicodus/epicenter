class AttendanceSignInClassroomController < ApplicationController
  before_action :normalize
  before_action :redirect_if_not_in_classroom
  before_action :redirect_if_invalid_credentials, only: [:create]
  before_action :redirect_if_not_classroom_time, only: [:create]

  def create
    student_1 = Student.find_by(email: params[:email1])
    student_2 = Student.find_by(email: params[:email2]) unless params[:email2] == params[:email1]
    if student_2
      sign_in_pairs(student_1, student_2)
    else
      sign_in_solo(student_1)
    end
  end

private

  def normalize
    params[:email2] = params[:password2] = nil if params[:email2] == params[:email1]
  end

  def redirect_if_not_in_classroom
    if !IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      return redirect_back(fallback_location: root_path, alert: "Attendance sign in unavailable. If you are an online student, please sign into attendance through Epicenter.")
    end
  end

  def redirect_if_invalid_credentials
    student_1 = Student.find_by(email: params[:email1])
    return fail('Invalid login credentials.') unless student_1.try(:valid_password?, params[:password1])
    if params[:email2].present?
      student_2 = Student.find_by(email: params[:email2])
      return fail('Invalid login credentials.') unless student_2.try(:valid_password?, params[:password2])
    end
  end

  def redirect_if_not_classroom_time
    if Time.zone.now.friday?
      return redirect_to root_path, alert: 'Attendance sign in not required on Fridays.'
    end
    student_1 = Student.find_by(email: params[:email1])
    student_2 = Student.find_by(email: params[:email2])
    if student_1 && student_2 && !student_1.is_attendance_available? && !student_2.is_attendance_available?
      return fail("Class is not currently in session for #{student_1.name} or #{student_2.name}. No attendance records created.")
    elsif !student_1.is_attendance_available?
      return fail("Class is not currently in session for #{student_1.name}. No attendance records created.")
    elsif student_2 && !student_2.is_attendance_available?
      return fail("Class is not currently in session for #{student_2.name}. No attendance records created.")
    end
  end

  def sign_in_solo(student)
    record = AttendanceRecord.find_or_initialize_by(student: student, date: Time.zone.now.to_date)
    record.station = params[:station]
    record.pair_ids = []
    if record.save
      return redirect_to welcome_path, alert: "Welcome #{student.name}. <strong>Your sign in time has been recorded as #{record.created_at.strftime('%I:%M %p')}, but you are signed in without a pair.</strong><br><a href='/sign_in_classroom'>Sign in again to record your pair.</a> (Doing so will not affect your sign in time.)"
    else
      return fail("Something went wrong: " + record.errors.full_messages.join(", "))
    end
  end

  def sign_in_pairs(student_1, student_2)
    record_1 = AttendanceRecord.find_or_initialize_by(student: student_1, date: Time.zone.now.to_date)
    record_2 = AttendanceRecord.find_or_initialize_by(student: student_2, date: Time.zone.now.to_date)
    record_1.station = params[:station]
    record_2.station = params[:station]
    record_1.pair_ids = [student_2.id]
    record_2.pair_ids = [student_1.id]
    if record_1.save && record_2.save
      return redirect_to welcome_path, notice: "Welcome #{student_1.name} and #{student_2.name}. Your sign in times have been recorded as #{record_1.created_at.strftime('%I:%M %p')} (#{student_1.name}) and #{record_2.created_at.strftime('%I:%M %p')} (#{student_2.name})."
    else
      return fail('Something went wrong: ' + record_1.errors.full_messages.join(', ') + '; ' + record_2.errors.full_messages.join(', '))
    end
  end

  def fail(message)
    flash[:alert] = message
    @email1 = params[:email1]
    @email2 = params[:email2]
    @station = params[:station]
    render :new
  end
end
