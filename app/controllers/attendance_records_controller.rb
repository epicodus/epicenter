class AttendanceRecordsController < ApplicationController
  def index
    @student = Student.find(params[:student_id])
  end
end
