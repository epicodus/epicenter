class AttendanceRecordAmendmentsController < ApplicationController
  authorize_resource

  def new
    @attendance_record_amendment = AttendanceRecordAmendment.new
    if params.has_key?(:student)
      @student = Student.find(params[:student])
      @day = params[:day]
    end
  end

  def create
    @attendance_record_amendment = AttendanceRecordAmendment.new(attendance_record_amendment_params)
    if @attendance_record_amendment.save
      student = Student.find(params[:attendance_record_amendment][:student_id])
      redirect_to new_attendance_record_amendment_path, notice: "#{student.name}'s attendance record has been amended."
    else
      render :new
    end
  end

private

  def attendance_record_amendment_params
    params.require(:attendance_record_amendment).permit(:student_id, :status, :date)
  end
end
