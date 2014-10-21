class AttendanceStatisticsController < ApplicationController
  def show
    @cohort = Cohort.find(params[:cohort_id])
    @attendance_statistic = CohortAttendanceStatistics.new(@cohort)
  end
end
