class AttendanceSignOutController < ApplicationController
  before_action :redirect_if_not_authorized_to_sign_out, only: [:create]

  def create
    student = Student.find_by(email: params[:email].downcase)
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: student)
    if attendance_record && student.try(:valid_password?, params[:password])
      sign_out_student(student, attendance_record)
    elsif !attendance_record && student.try(:valid_password?, params[:password])
      fail("You haven't signed in yet today.")
    else
      fail('Invalid email or password.')
    end
  end

private

  def redirect_if_not_authorized_to_sign_out
    if !is_weekday? || !IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      redirect_to root_path, alert: 'Unable to update attendance record.'
    end
  end

  def attendance_record_params
    params.permit(:signing_out, :student_id)
  end

  def sign_out_student(student, attendance_record)
    authorize! :update, attendance_record
    if attendance_record.update(attendance_record_params)
      sign_out student
      redirect_to sign_out_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated. Please remember to shut down your computer."
    else
      fail("Something went wrong: " + attendance_record.errors.full_messages.join(", "))
    end
  end

  def fail(message)
    redirect_to sign_out_path, alert: message
  end

end
