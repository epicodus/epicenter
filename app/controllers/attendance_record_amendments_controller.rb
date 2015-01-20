class AttendanceRecordAmendmentsController < ApplicationController
  def new
    @attendance_record_amendment = AttendanceRecordAmendment.new
  end

  def create
    @attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    if @attendance_record_amendment.save
      student = Student.find(params[:attendance_record_amendment][:student_id])
      redirect_to root_path, notice: "#{student.name}'s attendance record has been amended."
    else
      render :new, alert: 'Something went wrong. Please try again.'
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status).merge(date: parsed_date_params)
  end

  def parsed_date_params
    Date.new(
      params[:attendance_record_amendment][:"date(1i)"].to_i,
      params[:attendance_record_amendment][:"date(2i)"].to_i,
      params[:attendance_record_amendment][:"date(3i)"].to_i
    )
  end
end
