class AttendanceStatisticsController < ApplicationController
  def index
    @cohort = Cohort.current
    @attendance_statistic = CohortAttendanceStatistics.new(@cohort)
  end
end
