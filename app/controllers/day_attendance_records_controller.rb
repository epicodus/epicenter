class DayAttendanceRecordsController < ApplicationController

  before_filter :authenticate_admin!

  def index
    @cohort = Cohort.find(params[:cohort_id])
    @day = Date.parse(params[:day]) if params[:day]
  end
end
