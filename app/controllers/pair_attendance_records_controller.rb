class PairAttendanceRecordsController < ApplicationController

  def destroy_multiple
    AttendanceRecord.destroy(params[:ids])
    flash[:alert] = 'Attendance record'.pluralize(params[:ids].count) + " has".pluralize(params[:ids].count) + " been deleted."
    redirect_to sign_in_path
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit(:pair_ids)
  end
end
