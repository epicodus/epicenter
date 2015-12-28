class AttendanceRecordsController < ApplicationController
  # authorize_resource

  def destroy
    @attendance_record = AttendanceRecord.find(params[:id])
    @attendance_record.destroy
    redirect_to sign_in_path, alert: "Attendance record has been deleted."
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit(:signing_out, :student_id)
  end
end
