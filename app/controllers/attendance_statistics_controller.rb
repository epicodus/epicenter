class AttendanceStatisticsController < ApplicationController
  authorize_resource :cohort_attendance_statistics, only: :index
  authorize_resource :student_attendance_statistics, only: :show

  def index
    @cohort = Cohort.find(params[:cohort_id])
    @attendance_statistic = CohortAttendanceStatistics.new(@cohort)
    @class_days = @cohort.list_class_days
    @day = Date.parse(params[:day]) if params[:day]
  end

  def show
    @student_attendance_stats = StudentAttendanceStatistics.new(current_student)
  end

  def create
    @cohort = Cohort.find(params[:cohort_id])
    @day = params[:attendance_records][:day]
    redirect_to cohort_attendance_statistics_path(@cohort, day: @day)
  end
end
