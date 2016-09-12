class AttendanceRecordsController < ApplicationController
  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, @student
  end
end
