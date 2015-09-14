class AttendanceRecordsController < ApplicationController
  authorize_resource

  def index
    @students = current_admin.current_cohort.students.order(:name)
  end

  def create
    attendance_records = params[:pair_ids].map do |pair_id|
      { student_id: pair_id, pair_id: (params[:pair_ids] - [pair_id]).first }
    end
    @attendance_records = AttendanceRecord.create(attendance_records)
    if @attendance_records.all?(&:save)
      student_names = @attendance_records.map { |attendance_record| attendance_record.student.name }
      flash[:notice] = "Welcome #{student_names.join(' and ')}."
      flash[:secure] =  view_context.link_to("Wrong student?",
                  destroy_multiple_attendance_records_path(ids: @attendance_records.map { |i| i.id }),
                  data: {method: :delete})
      redirect_to attendance_path
    else
      flash[:alert] = "Something went wrong: " + @attendance_records.first.errors.full_messages.join(", ")
      redirect_to attendance_path
    end
  end

  def update
    @attendance_record = AttendanceRecord.find(params[:id])
    if @attendance_record.update(attendance_record_params)
      redirect_to attendance_path, notice: "#{@attendance_record.student.name} successfully updated."
    else
      flash[:alert] = "Something went wrong: " + @attendance_record.errors.full_messages.join(", ")
      redirect_to attendance_path
    end
  end

  def destroy
    @attendance_record = AttendanceRecord.find(params[:id])
    @attendance_record.destroy
    redirect_to attendance_path, alert: "Attendance record has been deleted."
  end

  def destroy_multiple
    AttendanceRecord.destroy(params[:ids])
    redirect_to attendance_path, alert: "Attendance records have been deleted."
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit(:signing_out, :student_id)
  end
end
