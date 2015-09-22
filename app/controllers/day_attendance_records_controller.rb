class DayAttendanceRecordsController < ApplicationController

  def index
    @cohort = Cohort.find(params[:cohort_id])
    @day = Date.parse(params[:day]) if params[:day]
  end
end
