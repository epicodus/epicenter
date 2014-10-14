class AttendanceStatisticsController < ApplicationController
  def index
    @attendance_record_data_points = AttendanceRecord.group_by_day(:created_at).count
  end
end
