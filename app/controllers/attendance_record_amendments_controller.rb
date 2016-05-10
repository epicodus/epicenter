class AttendanceRecordAmendmentsController < ApplicationController
  authorize_resource

  def new
    @course = params[:course] ? Course.find(params[:course]) : current_course
    @attendance_record_amendment = AttendanceRecordAmendment.new(student_id: params[:student], date: params[:day])
  end

  def create
    @attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    if @attendance_record_amendment.save
      student = Student.find(params[:attendance_record_amendment][:student_id])
      redirect_to student_courses_path(student), notice: "The attendance record for #{student.name} on #{@attendance_record_amendment.date.to_date.strftime('%A, %B %d, %Y')} has been amended to #{@attendance_record_amendment.status}."
    else
      @course = params[:course] ? Course.find(params[:course]) : current_course
      render 'new'
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status, :date)
  end
end
