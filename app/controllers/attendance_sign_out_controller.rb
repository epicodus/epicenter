class AttendanceSignOutController < ApplicationController

  def create
    student = Student.find_by(email: params[:email].downcase)
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: student)
    if attendance_record && student.try(:valid_password?, params[:password])
      authorize! :update, attendance_record
      if attendance_record.update(attendance_record_params)
        sign_out student
        redirect_to sign_out_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated."
      else
        flash.now[:alert] = "Something went wrong: " + attendance_record.errors.full_messages.join(", ")
        render 'new'
      end
    elsif !attendance_record && student.try(:valid_password?, params[:password])
      flash.now[:alert] = "You haven't signed in yet today."
      render 'new'
    else
      flash.now[:alert] = 'Invalid email or password.'
      render 'new'
    end
  end

private

  def attendance_record_params
    params.permit(:signing_out, :student_id)
  end
end
