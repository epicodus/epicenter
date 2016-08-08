class AttendanceSignOutController < ApplicationController

  def create
    if is_weekday? && IpLocation.is_local_computer?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      student = Student.find_by(email: params[:email].downcase)
      attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: student)
      if attendance_record && student.try(:valid_password?, params[:password])
        sign_out_student(student, attendance_record)
      elsif !attendance_record && student.try(:valid_password?, params[:password])
        alert_about_not_signing_in
      else
        redirect_to sign_out_path, alert: 'Invalid email or password.'
      end
    else
      redirect_to sign_out_path, alert: 'Unable to update attendance record.'
    end
  end

private

  def attendance_record_params
    params.permit(:signing_out, :student_id)
  end

  def sign_out_student(student, attendance_record)
    authorize! :update, attendance_record
    if attendance_record.update(attendance_record_params)
      sign_out student
      redirect_to sign_out_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated."
    else
      redirect_to sign_out_path, alert: "Something went wrong: " + attendance_record.errors.full_messages.join(", ")
    end
  end

  def alert_about_not_signing_in
    redirect_to sign_out_path, alert: "You haven't signed in yet today."
  end
end