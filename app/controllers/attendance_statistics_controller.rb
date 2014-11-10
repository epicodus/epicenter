class AttendanceStatisticsController < ApplicationController
  authorize_resource :cohort_attendance_statistics

  def index
    @cohort = Cohort.find(params[:cohort_id])
    @attendance_statistic = CohortAttendanceStatistics.new(@cohort)
  end
end
