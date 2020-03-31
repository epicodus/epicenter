class AttendanceRecordAmendmentsController < ApplicationController
  authorize_resource

  def new
    @course = params[:course] ? Course.find(params[:course]) : current_course
    day = params[:day]
    status = params[:status] || "Absent"
    if params[:student]
      student = Student.find(params[:student])
      pair = student.pair_on_day(day)
      pair_id = pair ? pair.id : nil
    end
    @attendance_record_amendment = AttendanceRecordAmendment.new(student_id: params[:student], date: day, pair_id: pair_id, status: status)
  end

  def create
    @attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    @student = Student.find(params[:attendance_record_amendment][:student_id])
    day = Date.parse(@attendance_record_amendment.date) if @attendance_record_amendment.date
    @course = @student.courses.find_by('start_date <= ? AND end_date >= ?', day, day) || @student.course
    if @attendance_record_amendment.save
      respond_to do |format|
        format.html { redirect_to course_student_path(@course, @student), notice: "The attendance record for #{@student.name} on #{@attendance_record_amendment.date.to_date.strftime('%A, %B %d, %Y')} has been amended to #{@attendance_record_amendment.status}." }
        format.js { render 'create' }
      end
    else
      respond_to do |format|
        format.html { render 'new' }
        format.js do
          flash[:alert] = "There was a problem updating attendance status."
          render js: "window.location.pathname ='#{course_day_attendance_records_path(@course, day: params[:attendance_records][:day])}'"
        end
      end
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status, :date, :pair_id)
  end
end
