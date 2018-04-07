class RatingsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    @students = @course.students.order(:name)
    authorize! :manage, @course
  end
end
