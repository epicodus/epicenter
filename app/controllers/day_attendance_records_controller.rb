class DayAttendanceRecordsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @course = Course.find(params[:course_id])
    @day = Date.parse(params[:day]) if params[:day]
  end

  def create
    course = Course.find(params[:course_id])
    redirect_to course_day_attendance_records_path(course, day: params[:attendance_records][:day])
  end
end
