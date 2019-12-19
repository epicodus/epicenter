class AttendanceSignInController < ApplicationController
  before_action :normalize_input, only: [:create]
  before_action :redirect_if_not_in_classroom, only: [:create]
  before_action :redirect_if_invalid_credentials, only: [:create]
  before_action :redirect_if_not_classroom_day, only: [:create]

  def create
    student_1 = Student.find_by(email: params[:email1])
    student_2 = Student.find_by(email: params[:email2])
    if params[:email2].present?
      sign_in_pairs(student_1, student_2)
    else
      sign_in_solo(student_1)
    end
  end

private

  def normalize_input
    params[:email1].downcase!
    params[:email2].downcase!
    params[:email2] = '' if params[:email2] == params[:email1]
  end

  def redirect_if_not_in_classroom
    if !IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      redirect_to root_path, alert: 'Attendance sign in not available.'
    end
  end

  def redirect_if_invalid_credentials
    student_1 = Student.find_by(email: params[:email1])
    fail('Invalid login credentials.') unless student_1.try(:valid_password?, params[:password1])
    if params[:email2].present?
      student_2 = Student.find_by(email: params[:email2])
      fail('Invalid login credentials.') unless student_2.try(:valid_password?, params[:password2])
    end
  end

  def redirect_if_not_classroom_day
    fail('Attendance sign in not required on Fridays.') if Time.zone.now.friday?
    student_1 = Student.find_by(email: params[:email1])
    fail('This does not appear to be a class day for you.') unless student_1.course.try(:is_class_day?)
    if params[:email2].present?
      student_2 = Student.find_by(email: params[:email2])
      fail('This does not appear to be a class day for you.') unless student_2.course.try(:is_class_day?)
    end
  end

  def sign_in_solo(student)
    record = AttendanceRecord.find_or_initialize_by(student: student, date: Time.zone.now.to_date)
    record.station = params[:station]
    if record.save
      redirect_to welcome_path, alert: "Welcome #{student.name}. <strong>Your sign in time has been recorded, but you are signed in without a pair.</strong><br>Sign in again at <a href='/sign_in'>epicenter.epicodus.com/sign_in</a> to record your pair. (Doing so will not affect your sign in time.)"
    else
      fail("Something went wrong: " + record.errors.full_messages.join(", "))
    end
  end

  def sign_in_pairs(student_1, student_2)
    record_1 = AttendanceRecord.find_or_initialize_by(student: student_1, date: Time.zone.now.to_date)
    record_2 = AttendanceRecord.find_or_initialize_by(student: student_2, date: Time.zone.now.to_date)
    record_1.station = params[:station]
    record_2.station = params[:station]
    record_1.pair_id = student_2.id
    record_2.pair_id = student_1.id
    if record_1.save && record_2.save
      redirect_to welcome_path, notice: "Welcome #{student_1.name} and #{student_2.name}. Your attendance records have been created."
    else
      fail('Something went wrong: ' + record_1.errors.full_messages.join(', ') + '; ' + record_2.errors.full_messages.join(', '))
    end
  end

  def fail(message)
    redirect_to sign_in_path, alert: message
  end
end
