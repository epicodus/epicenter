class RatingsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    if params[:all]
      @students = @course.students.per(@course.students.count)
    else
      @students = @course.students.order(:name).page(params[:page]).per(15)
    end
  end
end
