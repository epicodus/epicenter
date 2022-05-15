class AttendanceSignOutRemoteController < ApplicationController
  before_action :redirect_if_not_online_student

  def new
    @student = current_student
    authorize! :read, @student
    if @student.attendance_records.today.any?
      render :new
    else
      redirect_back(fallback_location: root_path, alert: "You haven't signed in yet today.")
    end
  end

  def create
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: current_student)
    authorize! :update, attendance_record
    attendance_record.signing_out = true
    if attendance_record.save
      redirect_to root_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated."
    else
      redirect_back(fallback_location: root_path, alert: attendance_record.errors.full_messages.join(", "))
    end
  end

private

  def redirect_if_not_online_student
    unless current_student.online?
      redirect_back(fallback_location: root_path, alert: "Attendance sign out unavailable.")
    end
  end
end
