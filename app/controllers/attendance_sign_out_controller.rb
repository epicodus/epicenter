class AttendanceSignOutController < ApplicationController

  def create
    student = Student.find_by(email: params[:email])
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: student)
    if student.valid_password?(params[:password]) && attendance_record
      authorize! :update, attendance_record
      if attendance_record.update(attendance_record_params)
        redirect_to sign_out_path, notice: "Goodbye #{attendance_record.student.name}"
      else
        flash[:alert] = "Something went wrong: " + attendance_record.errors.full_messages.join(", ")
        render 'new'
      end
    elsif student.valid_password?(params[:password]) && !attendance_record
      flash[:alert] = "You haven't signed in yet today."
      render 'new'
    else
      flash[:alert] = 'Invalid email or password.'
      render 'new'
    end
  end

private

  def attendance_record_params
    params.permit(:signing_out, :student_id)
  end
end
