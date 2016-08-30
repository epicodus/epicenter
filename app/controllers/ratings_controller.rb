class RatingsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    @students = @course.students.order(:name).page(params[:page]).per(15)
    @students = @students.per(@course.students.count) if params[:all]
  end
end
