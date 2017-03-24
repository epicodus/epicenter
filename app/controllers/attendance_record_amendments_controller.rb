class AttendanceRecordAmendmentsController < ApplicationController
  authorize_resource

  def new
    @course = params[:course] ? Course.find(params[:course]) : current_course
    day = params[:day]
    if params[:student]
      student = Student.find(params[:student])
      pair = student.pair_on_day(day)
      pair_id = pair ? pair.id : nil
    end
    @attendance_record_amendment = AttendanceRecordAmendment.new(student_id: params[:student], date: day, pair_id: pair_id)
  end

  def create
    @attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    if @attendance_record_amendment.save
      student = Student.find(params[:attendance_record_amendment][:student_id])
      day = Date.parse(@attendance_record_amendment.date)
      course = student.courses.find_by('start_date <= ? AND end_date >= ?', day, day) || student.course
      redirect_to course_student_path(course, student), notice: "The attendance record for #{student.name} on #{@attendance_record_amendment.date.to_date.strftime('%A, %B %d, %Y')} has been amended to #{@attendance_record_amendment.status}."
    else
      @course = params[:course] ? Course.find(params[:course]) : current_course
      render 'new'
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status, :date, :pair_id)
  end
end
