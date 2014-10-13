class AttendanceStatisticsController < ApplicationController
  def index
    @students = User.by_absences
  end
end
