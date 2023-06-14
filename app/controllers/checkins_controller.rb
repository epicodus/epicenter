class CheckinsController < ApplicationController
  authorize_resource

  def index
    @course = Course.find(params[:course_id])
  end

  def create
    student = Student.find(params[:student_id])
    checkin = student.checkins.build(admin: current_admin)
    if checkin.save
      redirect_back(fallback_location: student_courses_path(student), notice: "Check-in created for #{student.name}.")
    else
      render :new
    end
  end
end
