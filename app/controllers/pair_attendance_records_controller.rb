class PairAttendanceRecordsController < ApplicationController

  def create
    @attendance_records = params[:pair_ids].map do |pair_id|
      AttendanceRecord.new({
        student_id: pair_id,
        pair_id: params[:pair_ids].reverse.slice(params[:pair_ids].index(pair_id))
      })
    end
    if @attendance_records.all? { |record| record.save }
      student_names = @attendance_records.map { |attendance_record| attendance_record.student.name }
      flash[:notice] = "Welcome #{student_names.join(' and ')}."
      flash[:secure] =  view_context.link_to("Wrong student?",
                  destroy_multiple_pair_attendance_records_path(ids: @attendance_records.map(&:id)),
                  data: {method: :delete})
      redirect_to attendance_path
    else
      flash[:alert] = "Something went wrong: " + @attendance_records.first.errors.full_messages.join(", ")
      redirect_to attendance_path
    end
  end

  def destroy_multiple
    AttendanceRecord.destroy(params[:ids])
    flash[:alert] = 'Attendance record'.pluralize(params[:ids].count) + " has".pluralize(params[:ids].count) + " been deleted."
    redirect_to attendance_path
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit(:pair_ids)
  end
end
