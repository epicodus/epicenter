class AttendanceRecordsController < ApplicationController
  authorize_resource

  def index
    @students = current_admin.current_cohort.students
  end

  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)
    if @attendance_record.save
      flash[:notice] = "Welcome #{@attendance_record.student.name}"
      flash[:secure] =  view_context.link_to("Not you?",
                        attendance_record_path(@attendance_record),
                        data: {method: :delete})
      redirect_to attendance_path
    end
  end

  def destroy
    @attendance_record = AttendanceRecord.find(params[:id])
    @attendance_record.destroy
    redirect_to attendance_path, alert: "Attendance record has been deleted."
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit(:student_id)
  end
end
