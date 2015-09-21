class AttendanceRecordAmendmentsController < ApplicationController
  authorize_resource

  def new
    @attendance_record_amendment = AttendanceRecordAmendment.new
    @attendance_record_amendment.student_id = params[:student]
    @attendance_record_amendment.date = params[:day]
  end

  def create
    attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    if attendance_record_amendment.save
      student = Student.find(params[:attendance_record_amendment][:student_id])
      check_referring_url(student)
    else
      render :new
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status, :date)
  end

  def check_referring_url(student)
    if request.referer.include?('attendance_statistics')
      day = params[:attendance_record_amendment][:date]
      redirect_to cohort_attendance_statistics_path(student.cohort, day: day), notice: "#{student.name}'s attendance record has been amended."
    else
      student = Student.find(params[:attendance_record_amendment][:student_id])
      redirect_to student_path(student), notice: "#{student.name}'s attendance record has been amended."
    end
  end
end
