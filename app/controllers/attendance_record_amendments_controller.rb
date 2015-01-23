class AttendanceRecordAmendmentsController < ApplicationController
  authorize_resource

  def new
    @attendance_record_amendment = AttendanceRecordAmendment.new
  end

  def create
    @attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    if @attendance_record_amendment.save
      student = Student.find(params[:attendance_record_amendment][:student_id])
      redirect_to new_attendance_record_amendment_path, notice: "#{student.name}'s attendance record has been amended."
    else
      render :new, alert: 'Something went wrong. Please try again.'
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status, :date)
  end
end
