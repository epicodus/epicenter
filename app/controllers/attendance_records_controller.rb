class AttendanceRecordsController < ApplicationController
  def index
    @students = User.all #TODO default scope this to the current class
  end

  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)
    if @attendance_record.save
      redirect_to attendance_path, notice: "Welcome #{@attendance_record.user.name}. Glad you're here!"
    end
  end

  private

  def attendance_record_params
    params.require(:attendance_record).permit(:user_id)
  end
end
