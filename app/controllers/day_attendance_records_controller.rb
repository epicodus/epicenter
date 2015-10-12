class DayAttendanceRecordsController < ApplicationController

  before_filter :authenticate_admin!

  def index
    @course = Course.find(params[:course_id])
    @day = Date.parse(params[:day]) if params[:day]
  end
end
