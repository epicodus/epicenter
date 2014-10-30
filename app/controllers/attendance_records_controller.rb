class AttendanceRecordsController < ApplicationController
  def index
    @students = User.all #TODO default scope this to the current class
  end

  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)
    if @attendance_record.save
      flash[:notice] = "Welcome #{@attendance_record.user.name}"
      flash[:secure] =  view_context.link_to("Not you?",
                        attendance_record_path(@attendance_record),
                        data: {method: :delete})
      redirect_to attendance_path
    end
  end

  def destroy
    @attendance_record = AttendanceRecord.find(params[:id])
    @attendance_record.destroy
    flash[:alert] = "Attendance record has been deleted."
    redirect_to attendance_path
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit(:user_id)
  end
end
