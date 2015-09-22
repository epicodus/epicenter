class DayAttendanceRecordsController < ApplicationController

  def show
    @cohort = Cohort.find(params[:cohort_id])
    @day = Date.parse(params[:day]) if params[:day]
  end
end
