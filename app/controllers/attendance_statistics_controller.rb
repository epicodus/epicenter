class AttendanceStatisticsController < ApplicationController
  def show
    @cohort = Cohort.current
    @attendance_statistic = CohortAttendanceStatistics.new(@cohort)
  end
end
