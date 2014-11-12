class AttendanceStatisticsController < ApplicationController
  authorize_resource :cohort_attendance_statistics, only: :index
  authorize_resource :student_attendance_statistics, only: :show

  def index
    @cohort = Cohort.find(params[:cohort_id])
    @attendance_statistic = CohortAttendanceStatistics.new(@cohort)
  end

  def show
    @student_attendance_stats = StudentAttendanceStatistics.new(current_student)
  end
end
